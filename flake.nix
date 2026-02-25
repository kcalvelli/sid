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
