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
              # 1. `futures` and `async-stream` crates needed but not in [dependencies]
              sed -i '/^futures-util/a futures = "0.3"\nasync-stream = "0.3"' Cargo.toml

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

              # ── /v1/models: static OpenAI-compatible model list (no auth) ──

              # 8.6. Add /v1/models endpoint returning static model list for HA discovery
              ${pkgs.python3}/bin/python3 -c "
              with open('src/gateway/mod.rs', 'r') as f:
                  src = f.read()

              # Add the handler function right before handle_webhook
              handler = (
                  'async fn handle_models() -> impl axum::response::IntoResponse {\n'
                  '    ([(\x22content-type\x22, \x22application/json\x22)],\n'
                  '     r#\x22{\x22object\x22:\x22list\x22,\x22data\x22:[{\x22id\x22:\x22sid\x22,\x22object\x22:\x22model\x22}]}\x22#)\n'
                  '}\n\n'
              )
              old_webhook = 'async fn handle_webhook('
              assert old_webhook in src, f'Could not find: {old_webhook}'
              src = src.replace(old_webhook, handler + old_webhook, 1)

              # Add route to Router (after /health)
              old_health = '.route(\x22/health\x22, get(handle_health))'
              new_health = old_health + '\n        .route(\x22/v1/models\x22, get(handle_models))'
              assert old_health in src, f'Could not find: {old_health}'
              src = src.replace(old_health, new_health, 1)

              with open('src/gateway/mod.rs', 'w') as f:
                  f.write(src)
              "

              # ── /v1/chat/completions: OpenAI-to-Anthropic translation proxy ──

              # 8.7. Copy openai_proxy module and declare it in mod.rs
              cp ${./patches/openai_proxy.rs} src/gateway/openai_proxy.rs
              ${pkgs.python3}/bin/python3 -c "
              with open('src/gateway/mod.rs', 'r') as f:
                  src = f.read()
              # Add module declaration after 'pub mod ws;'
              src = src.replace('pub mod ws;', 'pub mod ws;\npub mod openai_proxy;', 1)
              with open('src/gateway/mod.rs', 'w') as f:
                  f.write(src)
              "

              # 8.8. Wire /v1/chat/completions as sub-router with 1MB body limit
              ${pkgs.python3}/bin/python3 -c "
              with open('src/gateway/mod.rs', 'r') as f:
                  src = f.read()
              # Create chat_completions_router before config_put_router
              old_config = 'let config_put_router'
              new_router = (
                  'let chat_completions_router = Router::new()\n'
                  '        .route(\"/v1/chat/completions\", post(openai_proxy::handle_chat_completions))\n'
                  '        .layer(RequestBodyLimitLayer::new(1_048_576));\n'
                  '\n'
                  '    let config_put_router'
              )
              assert old_config in src, f'Could not find: {old_config}'
              src = src.replace(old_config, new_router, 1)
              # Merge chat_completions_router after config_put_router merge
              old_merge = '.merge(config_put_router)'
              new_merge = old_merge + '\n        .merge(chat_completions_router)'
              assert old_merge in src, f'Could not find: {old_merge}'
              src = src.replace(old_merge, new_merge, 1)
              with open('src/gateway/mod.rs', 'w') as f:
                  f.write(src)
              "

              # ── Email self-loop prevention: skip emails from own address ──

              # 8.9. Patch email_channel.rs to ignore emails sent by self (prevents reply loops)
              ${pkgs.python3}/bin/python3 -c "
              with open('src/channels/email_channel.rs', 'r') as f:
                  src = f.read()
              old = (
                  '            // Check allowlist\n'
                  '            if !self.is_sender_allowed(&email.sender) {\n'
                  '                warn!(\"Blocked email from {}\", email.sender);\n'
                  '                continue;\n'
                  '            }'
              )
              new = (
                  '            // Check allowlist\n'
                  '            if !self.is_sender_allowed(&email.sender) {\n'
                  '                warn!(\"Blocked email from {}\", email.sender);\n'
                  '                continue;\n'
                  '            }\n'
                  '\n'
                  '            // Skip emails from self (prevent reply loops)\n'
                  '            if email.sender.eq_ignore_ascii_case(&self.config.from_address) {\n'
                  '                info!(\"Ignoring email from self ({})\", email.sender);\n'
                  '                continue;\n'
                  '            }'
              )
              assert old in src, f'Could not find allowlist check in email_channel.rs'
              src = src.replace(old, new, 1)
              with open('src/channels/email_channel.rs', 'w') as f:
                  f.write(src)
              "

              # 8.10. Pass original subject via thread_ts so replies get "Re: ..." subjects
              ${pkgs.python3}/bin/python3 -c "
              with open('src/channels/email_channel.rs', 'r') as f:
                  src = f.read()

              # In process_unseen: extract subject from content and set thread_ts
              old = (
                  '            let msg = ChannelMessage {\n'
                  '                id: email.msg_id,\n'
                  '                reply_target: email.sender.clone(),\n'
                  '                sender: email.sender,\n'
                  '                content: email.content,\n'
                  '                channel: \"email\".to_string(),\n'
                  '                timestamp: email.timestamp,\n'
                  '                thread_ts: None,\n'
                  '            };'
              )
              new = (
                  '            // Extract subject for reply threading\n'
                  '            let _email_subj = if email.content.starts_with(\"Subject: \") {\n'
                  '                email.content.lines().next()\n'
                  '                    .map(|l| l.trim_start_matches(\"Subject: \").to_string())\n'
                  '            } else {\n'
                  '                None\n'
                  '            };\n'
                  '            let msg = ChannelMessage {\n'
                  '                id: email.msg_id,\n'
                  '                reply_target: email.sender.clone(),\n'
                  '                sender: email.sender,\n'
                  '                content: email.content,\n'
                  '                channel: \"email\".to_string(),\n'
                  '                timestamp: email.timestamp,\n'
                  '                thread_ts: _email_subj,\n'
                  '            };'
              )
              assert old in src, f'Could not find ChannelMessage creation in process_unseen'
              src = src.replace(old, new, 1)

              # In send(): use thread_ts as Re: subject fallback before 'ZeroClaw Message'
              old_send = (
                  '        // Use explicit subject if provided, otherwise fall back to legacy parsing or default\n'
                  '        let (subject, body) = if let Some(ref subj) = message.subject {\n'
                  '            (subj.as_str(), message.content.as_str())\n'
                  '        } else if message.content.starts_with(\"Subject: \") {\n'
                  '            if let Some(pos) = message.content.find(' + chr(39) + chr(92) + 'n' + chr(39) + ') {\n'
                  '                (&message.content[9..pos], message.content[pos + 1..].trim())\n'
                  '            } else {\n'
                  '                (\"ZeroClaw Message\", message.content.as_str())\n'
                  '            }\n'
                  '        } else {\n'
                  '            (\"ZeroClaw Message\", message.content.as_str())\n'
                  '        };'
              )
              new_send = (
                  '        // Use explicit subject if provided, otherwise fall back to legacy parsing,\n'
                  '        // thread subject (for email replies), or default\n'
                  '        let _thread_subject;\n'
                  '        let (subject, body) = if let Some(ref subj) = message.subject {\n'
                  '            (subj.as_str(), message.content.as_str())\n'
                  '        } else if message.content.starts_with(\"Subject: \") {\n'
                  '            if let Some(pos) = message.content.find(' + chr(39) + chr(92) + 'n' + chr(39) + ') {\n'
                  '                (&message.content[9..pos], message.content[pos + 1..].trim())\n'
                  '            } else {\n'
                  '                (\"ZeroClaw Message\", message.content.as_str())\n'
                  '            }\n'
                  '        } else if let Some(ref ts) = message.thread_ts {\n'
                  '            _thread_subject = if ts.starts_with(\"Re: \") {\n'
                  '                ts.clone()\n'
                  '            } else {\n'
                  '                format!(\"Re: {}\", ts)\n'
                  '            };\n'
                  '            (_thread_subject.as_str(), message.content.as_str())\n'
                  '        } else {\n'
                  '            (\"ZeroClaw Message\", message.content.as_str())\n'
                  '        };'
              )
              assert old_send in src, f'Could not find subject determination in send()'
              src = src.replace(old_send, new_send, 1)

              with open('src/channels/email_channel.rs', 'w') as f:
                  f.write(src)
              "

              # 8.11. Save sent emails to IMAP Sent folder (best-effort)
              ${pkgs.python3}/bin/python3 -c "
              with open('src/channels/email_channel.rs', 'r') as f:
                  src = f.read()

              # Add sent_folder field to EmailConfig
              old_cfg = (
                  '    /// Allowed sender addresses/domains (empty = deny all, [\"*\"] = allow all)\n'
                  '    #[serde(default)]\n'
                  '    pub allowed_senders: Vec<String>,'
              )
              new_cfg = (
                  '    /// Allowed sender addresses/domains (empty = deny all, [\"*\"] = allow all)\n'
                  '    #[serde(default)]\n'
                  '    pub allowed_senders: Vec<String>,\n'
                  '    /// IMAP folder name for saving sent messages (default: \"Sent\")\n'
                  '    #[serde(default = \"default_sent_folder\")]\n'
                  '    pub sent_folder: String,'
              )
              assert old_cfg in src, f'Could not find allowed_senders in EmailConfig'
              src = src.replace(old_cfg, new_cfg, 1)

              # Add default_sent_folder function
              old_fn = 'fn default_true() -> bool {\n    true\n}'
              new_fn = (
                  'fn default_true() -> bool {\n'
                  '    true\n'
                  '}\n'
                  'fn default_sent_folder() -> String {\n'
                  '    \"Sent\".into()\n'
                  '}'
              )
              assert old_fn in src, f'Could not find default_true function'
              src = src.replace(old_fn, new_fn, 1)

              # Add sent_folder to Default impl
              old_default = '            allowed_senders: Vec::new(),\n        }'
              new_default = '            allowed_senders: Vec::new(),\n            sent_folder: default_sent_folder(),\n        }'
              assert old_default in src, f'Could not find allowed_senders in Default impl'
              src = src.replace(old_default, new_default, 1)

              # After SMTP send, append to Sent folder via IMAP
              old_sent = '        info!(\"Email sent to {}\", message.recipient);\n        Ok(())\n    }'
              new_sent = (
                  '        info!(\"Email sent to {}\", message.recipient);\n'
                  '\n'
                  '        // Save copy to IMAP Sent folder (best-effort, non-fatal)\n'
                  '        if !self.config.sent_folder.is_empty() {\n'
                  '            let raw_email = email.formatted();\n'
                  '            match self.connect_imap().await {\n'
                  '                Ok(mut imap_session) => {\n'
                  '                    match imap_session\n'
                  '                        .append(&self.config.sent_folder, Some(' + chr(34) + chr(92) + chr(92) + 'Seen' + chr(34) + '), None, &raw_email)\n'
                  '                        .await\n'
                  '                    {\n'
                  '                        Ok(_) => debug!(\"Saved to {} folder\", self.config.sent_folder),\n'
                  '                        Err(e) => warn!(\"Failed to save to {}: {}\", self.config.sent_folder, e),\n'
                  '                    }\n'
                  '                    let _ = imap_session.logout().await;\n'
                  '                }\n'
                  '                Err(e) => warn!(\"IMAP connect for Sent save failed: {}\", e),\n'
                  '            }\n'
                  '        }\n'
                  '\n'
                  '        Ok(())\n'
                  '    }'
              )
              assert old_sent in src, f'Could not find send() Ok return'
              src = src.replace(old_sent, new_sent, 1)

              with open('src/channels/email_channel.rs', 'w') as f:
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
