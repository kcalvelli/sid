{
  description = "Sid — cynical Gen X AI agent on ZeroClaw";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zeroclaw = {
      url = "github:zeroclaw-labs/zeroclaw";
      flake = false;  # source-only — we build it ourselves
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zeroclaw, agenix, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          zeroclaw = pkgs.rustPlatform.buildRustPackage {
            pname = "zeroclaw";
            version = "0.1.0";
            src = zeroclaw;

            cargoLock.lockFile = zeroclaw + "/Cargo.lock";

            buildFeatures = [ "memory-postgres" ];

            postPatch = ''
              # 1. `futures` crate removed from [dependencies] but still used in code
              sed -i '/^futures-util/a futures = "0.3"' Cargo.toml

              # ── Message timestamps (prepend ISO-8601 to all incoming messages) ──

              # 2. Channel messages: use real send-time from ChannelMessage.timestamp
              ${pkgs.python3}/bin/python3 -c "
              with open('src/channels/mod.rs', 'r') as f:
                  src = f.read()
              src = src.replace(
                  'pub mod clawdtalk;',
                  'use chrono::TimeZone;\n\npub mod clawdtalk;',
                  1
              )
              old = 'append_sender_turn(ctx.as_ref(), &history_key, ChatMessage::user(&msg.content));'
              q = chr(34)
              new = (
                  'let _ts = chrono::Local.timestamp_opt(msg.timestamp as i64, 0)\n'
                  '        .single()\n'
                  '        .unwrap_or_else(chrono::Local::now);\n'
                  '    let _stamped_content = format!(' + q + '[{}] {}' + q + ', _ts.format(' + q + '%Y-%m-%dT%H:%M:%S%:z' + q + '), msg.content);\n'
                  '    append_sender_turn(ctx.as_ref(), &history_key, ChatMessage::user(&_stamped_content));'
              )
              src = src.replace(old, new, 1)
              with open('src/channels/mod.rs', 'w') as f:
                  f.write(src)
              "

              # 3. Heartbeat messages: stamp with Local::now() at dispatch
              ${pkgs.python3}/bin/python3 -c "
              with open('src/daemon/mod.rs', 'r') as f:
                  src = f.read()
              src = src.replace('use chrono::Utc;', 'use chrono::{Local, Utc};', 1)
              q = chr(34)
              old = 'let prompt = format!(' + q + '[Heartbeat Task] {task}' + q + ');'
              new = 'let prompt = format!(' + q + '[{}] [Heartbeat Task] {task}' + q + ', chrono::Local::now().format(' + q + '%Y-%m-%dT%H:%M:%S%:z' + q + '));'
              src = src.replace(old, new, 1)
              with open('src/daemon/mod.rs', 'w') as f:
                  f.write(src)
              "

              # 4. Webhook messages: stamp with Local::now() at receipt
              ${pkgs.python3}/bin/python3 -c "
              with open('src/gateway/mod.rs', 'r') as f:
                  src = f.read()
              src = src.replace(
                  'use crate::channels:',
                  'use chrono::Local;\nuse crate::channels:',
                  1
              )
              q = chr(34)
              old = 'let user_messages = vec![ChatMessage::user(message)];'
              new = ('let _stamped = format!(' + q + '[{}] {}' + q + ', chrono::Local::now().format(' + q + '%Y-%m-%dT%H:%M:%S%:z' + q + '), message);\n'
                     '    let user_messages = vec![ChatMessage::user(&_stamped)];')
              src = src.replace(old, new, 1)
              with open('src/gateway/mod.rs', 'w') as f:
                  f.write(src)
              "

              # ── XMPP channel (native Prosody integration) ──

              # 5. Copy XMPP channel source into the source tree
              cp ${./patches/xmpp.rs} src/channels/xmpp.rs

              # 6. Patch src/channels/mod.rs: add module declaration + re-export + channel instantiation
              ${pkgs.python3}/bin/python3 -c "
              with open('src/channels/mod.rs', 'r') as f:
                  src = f.read()

              # Add module declaration (after whatsapp_web)
              src = src.replace(
                  'pub mod whatsapp_web;\n',
                  'pub mod whatsapp_web;\npub mod xmpp;\n',
                  1
              )

              # Add re-export (after WhatsAppWebChannel)
              src = src.replace(
                  'pub use whatsapp_web::WhatsAppWebChannel;\n',
                  'pub use whatsapp_web::WhatsAppWebChannel;\npub use xmpp::XmppChannel;\n',
                  1
              )

              # Add XMPP channel to collect_configured_channels (before the closing 'channels' return)
              old_collect = '    channels\n}'
              new_collect = (
                  '    if let Some(ref xmpp_cfg) = config.channels_config.xmpp {\n'
                  '        channels.push(ConfiguredChannel {\n'
                  '            display_name: \"XMPP\",\n'
                  '            channel: Arc::new(XmppChannel::new(xmpp_cfg)),\n'
                  '        });\n'
                  '    }\n'
                  '\n'
                  '    channels\n'
                  '}'
              )
              # Find the LAST occurrence of 'channels\n}' in collect_configured_channels
              # by replacing from the end
              idx = src.rfind('    channels\n}')
              if idx is not None and idx > 2600:  # sanity: must be in collect_configured_channels area
                  src = src[:idx] + new_collect + src[idx + len(old_collect):]

              with open('src/channels/mod.rs', 'w') as f:
                  f.write(src)
              "

              # 7. Patch src/config/schema.rs: add xmpp field to ChannelsConfig + Default impl
              ${pkgs.python3}/bin/python3 -c "
              with open('src/config/schema.rs', 'r') as f:
                  src = f.read()

              # Add xmpp field to ChannelsConfig struct (after clawdtalk field)
              src = src.replace(
                  '    pub clawdtalk: Option<crate::channels::clawdtalk::ClawdTalkConfig>,',
                  ('    pub clawdtalk: Option<crate::channels::clawdtalk::ClawdTalkConfig>,\n'
                   '    /// XMPP channel configuration.\n'
                   '    pub xmpp: Option<crate::channels::xmpp::XmppConfig>,'),
                  1
              )

              # Add xmpp: None to Default impl (after clawdtalk: None)
              src = src.replace(
                  '            clawdtalk: None,',
                  '            clawdtalk: None,\n            xmpp: None,',
                  1
              )

              with open('src/config/schema.rs', 'w') as f:
                  f.write(src)
              "

              # 8. Patch src/tools/mod.rs: register XMPP tools when channel is configured
              ${pkgs.python3}/bin/python3 -c "
              with open('src/tools/mod.rs', 'r') as f:
                  src = f.read()

              # Add XMPP tools before the final boxed_registry_from_arcs call
              src = src.replace(
                  '    boxed_registry_from_arcs(tool_arcs)\n}',
                  '    // XMPP tools (conditionally registered when XMPP channel is configured)\n    if root_config.channels_config.xmpp.is_some() {\n        tool_arcs.extend(crate::channels::xmpp::xmpp_tools());\n    }\n\n    boxed_registry_from_arcs(tool_arcs)\n}',
                  1
              )

              with open('src/tools/mod.rs', 'w') as f:
                  f.write(src)
              "

              # ── Webhook tool loop: use full agent loop instead of simple chat ──

              # 8.5. Replace run_gateway_chat_simple with run_gateway_chat_with_tools in handle_webhook
              ${pkgs.python3}/bin/python3 -c "
              with open('src/gateway/mod.rs', 'r') as f:
                  src = f.read()
              # The webhook handler calls run_gateway_chat_simple (no tools, single-shot).
              # Switch to run_gateway_chat_with_tools which runs the full agent loop.
              # webhook_session_id (Option<&str>) is already extracted earlier in handle_webhook().
              old = 'run_gateway_chat_simple(&state, message).await'
              new = 'run_gateway_chat_with_tools(&state, message).await'
              assert old in src, f'Could not find: {old}'
              src = src.replace(old, new, 1)
              with open('src/gateway/mod.rs', 'w') as f:
                  f.write(src)
              "

              # ── Image vision: patch Anthropic provider for Claude vision API ──

              # 9. Add ImageSource struct + Image variant to NativeContentOut
              ${pkgs.python3}/bin/python3 -c "
              with open('src/providers/anthropic.rs', 'r') as f:
                  src = f.read()

              # Add ImageSource struct before NativeContentOut enum
              src = src.replace(
                  '#[derive(Debug, Serialize)]\n#[serde(tag = \"type\")]\nenum NativeContentOut {',
                  ('#[derive(Debug, Serialize)]\nstruct ImageSource {\n'
                   '    #[serde(rename = \"type\")]\n'
                   '    source_type: String,\n'
                   '    media_type: String,\n'
                   '    data: String,\n'
                   '}\n\n'
                   '#[derive(Debug, Serialize)]\n#[serde(tag = \"type\")]\nenum NativeContentOut {'),
                  1
              )

              # Add Image variant after ToolResult variant
              src = src.replace(
                  '    #[serde(rename = \"tool_result\")]\n    ToolResult {\n        tool_use_id: String,\n        content: String,\n        #[serde(skip_serializing_if = \"Option::is_none\")]\n        cache_control: Option<CacheControl>,\n    },\n}',
                  ('    #[serde(rename = \"tool_result\")]\n    ToolResult {\n        tool_use_id: String,\n        content: String,\n        #[serde(skip_serializing_if = \"Option::is_none\")]\n        cache_control: Option<CacheControl>,\n    },\n'
                   '    #[serde(rename = \"image\")]\n    Image {\n        source: ImageSource,\n    },\n}'),
                  1
              )

              with open('src/providers/anthropic.rs', 'w') as f:
                  f.write(src)
              "

              # 10. Declare vision capability on AnthropicProvider
              ${pkgs.python3}/bin/python3 -c "
              with open('src/providers/anthropic.rs', 'r') as f:
                  src = f.read()

              src = src.replace(
                  'impl Provider for AnthropicProvider {\n    async fn chat_with_system(',
                  ('impl Provider for AnthropicProvider {\n'
                   '    fn capabilities(&self) -> crate::providers::traits::ProviderCapabilities {\n'
                   '        crate::providers::traits::ProviderCapabilities {\n'
                   '            native_tool_calling: true,\n'
                   '            vision: true,\n'
                   '        }\n'
                   '    }\n\n'
                   '    async fn chat_with_system('),
                  1
              )

              with open('src/providers/anthropic.rs', 'w') as f:
                  f.write(src)
              "

              # 11. Add Image arm to apply_cache_to_last_message
              ${pkgs.python3}/bin/python3 -c "
              with open('src/providers/anthropic.rs', 'r') as f:
                  src = f.read()

              src = src.replace(
                  '                    NativeContentOut::ToolUse { .. } => {}\n                }',
                  '                    NativeContentOut::ToolUse { .. } => {}\n                    NativeContentOut::Image { .. } => {}\n                }',
                  1
              )

              with open('src/providers/anthropic.rs', 'w') as f:
                  f.write(src)
              "

              # 11. Patch convert_messages() to parse [IMAGE:] markers in user messages
              ${pkgs.python3}/bin/python3 -c "
              with open('src/providers/anthropic.rs', 'r') as f:
                  src = f.read()

              # Add helper functions before convert_messages
              old_fn = '    fn convert_messages(messages: &[ChatMessage]) -> (Option<SystemPrompt>, Vec<NativeMessage>) {'
              helper = (
                  '    /// Parse a data URI (data:mime;base64,payload) into an ImageSource.\n'
                  '    fn parse_data_uri_image(data_uri: &str) -> Option<ImageSource> {\n'
                  '        let rest = data_uri.strip_prefix(\"data:\")?;\n'
                  '        let (mime, payload) = rest.split_once(\";base64,\")?;\n'
                  '        if mime.is_empty() || payload.is_empty() {\n'
                  '            return None;\n'
                  '        }\n'
                  '        Some(ImageSource {\n'
                  '            source_type: \"base64\".to_string(),\n'
                  '            media_type: mime.to_string(),\n'
                  '            data: payload.to_string(),\n'
                  '        })\n'
                  '    }\n'
                  '\n'
                  '    /// Build content blocks from a message that may contain [IMAGE:data:...] markers.\n'
                  '    fn build_user_content_blocks(content: &str) -> Vec<NativeContentOut> {\n'
                  '        let (text, image_refs) = crate::multimodal::parse_image_markers(content);\n'
                  '        let mut blocks = Vec::new();\n'
                  '        if !text.is_empty() {\n'
                  '            blocks.push(NativeContentOut::Text {\n'
                  '                text,\n'
                  '                cache_control: None,\n'
                  '            });\n'
                  '        }\n'
                  '        for img_ref in &image_refs {\n'
                  '            if let Some(source) = Self::parse_data_uri_image(img_ref) {\n'
                  '                blocks.push(NativeContentOut::Image { source });\n'
                  '            }\n'
                  '        }\n'
                  '        if blocks.is_empty() {\n'
                  '            blocks.push(NativeContentOut::Text {\n'
                  '                text: content.to_string(),\n'
                  '                cache_control: None,\n'
                  '            });\n'
                  '        }\n'
                  '        blocks\n'
                  '    }\n'
                  '\n'
              )
              src = src.replace(old_fn, helper + old_fn, 1)

              # Replace the user message branch to use build_user_content_blocks
              old_user = (
                  '                _ => {\n'
                  '                    native_messages.push(NativeMessage {\n'
                  '                        role: \"user\".to_string(),\n'
                  '                        content: vec![NativeContentOut::Text {\n'
                  '                            text: msg.content.clone(),\n'
                  '                            cache_control: None,\n'
                  '                        }],\n'
                  '                    });\n'
                  '                }'
              )
              new_user = (
                  '                _ => {\n'
                  '                    native_messages.push(NativeMessage {\n'
                  '                        role: \"user\".to_string(),\n'
                  '                        content: Self::build_user_content_blocks(&msg.content),\n'
                  '                    });\n'
                  '                }'
              )
              src = src.replace(old_user, new_user, 1)

              with open('src/providers/anthropic.rs', 'w') as f:
                  f.write(src)
              "
            '';

            nativeBuildInputs = with pkgs; [ pkg-config ];
            buildInputs = with pkgs; [ openssl systemd ];

            # Skip tests — they need network/integration setup
            doCheck = false;

            meta = {
              description = "Zero overhead AI assistant";
              homepage = "https://github.com/zeroclaw-labs/zeroclaw";
              license = pkgs.lib.licenses.asl20;
              mainProgram = "zeroclaw";
            };
          };

          default = self.packages.${system}.zeroclaw;
        });

      nixosModules.default = { pkgs, ... }: {
        imports = [
          agenix.nixosModules.default
          ./modules/nixos
        ];
      };
    };
}
