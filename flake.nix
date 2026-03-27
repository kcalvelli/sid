{
  description = "Sid — cynical Gen X AI agent on ZeroClaw";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zeroclaw = {
      url = "github:zeroclaw-labs/zeroclaw/v0.6.3";
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
          lib = pkgs.lib;

          pwaOverlay = ./web/pwa;

          zeroclaw-web = pkgs.buildNpmPackage {
            pname = "zeroclaw-web";
            version = "0.6.3";
            src = zeroclaw;
            sourceRoot = "source/web";
            npmDepsHash = "sha256-RMiFoPj4cbUYONURsCp4FrNuy9bR1eRWqgAnACrVXsI=";
            postPatch = ''
              # PWA: inject manifest, service worker, icons, and registration module
              cp ${pwaOverlay}/manifest.json public/manifest.json
              cp ${pwaOverlay}/service-worker.js public/service-worker.js
              mkdir -p public/icons
              cp ${pwaOverlay}/icons/icon-192x192.png public/icons/icon-192x192.png
              cp ${pwaOverlay}/icons/icon-512x512.png public/icons/icon-512x512.png

              # PWA: add meta tags to index.html
              ${pkgs.gnused}/bin/sed -i '/<link rel="icon"/i\    <meta name="theme-color" content="#22d3ee" />\n    <meta name="apple-mobile-web-app-capable" content="yes" />\n    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />\n    <link rel="manifest" href="/_app/manifest.json" />\n    <link rel="apple-touch-icon" href="/_app/icons/icon-192x192.png" />' index.html

              # PWA: add service worker registration module
              cp ${pwaOverlay}/sw-register.ts src/sw-register.ts

              # PWA: register service worker in main.tsx
              ${pkgs.gnused}/bin/sed -i "1s|^|import { registerServiceWorker } from './sw-register';\n|" src/main.tsx
              echo "registerServiceWorker();" >> src/main.tsx
            '';
            installPhase = ''
              runHook preInstall
              cp -r dist $out
              runHook postInstall
            '';
          };
        in
        {
          zeroclaw = pkgs.rustPlatform.buildRustPackage {
            pname = "zeroclaw";
            version = "0.6.3";
            src = zeroclaw;

            cargoHash = "sha256-YZ+VKHG3k+GxbhMcuXGDca+qmrprNG4lDcR64ysGhRg=";


            patches = [
              ./patches/0001-fix-add-missing-futures-and-async-stream-crate-depen.patch
              ./patches/0002-feat-prepend-ISO-8601-timestamps-to-all-incoming-mes.patch
              ./patches/0003-feat-wire-XMPP-channel-into-channel-registry-and-con.patch
              ./patches/0004-feat-use-full-agent-loop-for-webhook-requests.patch
              ./patches/0005-feat-add-v1-models-endpoint-for-OpenAI-compatible.patch
              ./patches/0006-feat-wire-OpenAI-compatible-v1-chat-completions.patch
              ./patches/0007-fix-skip-emails-from-own-address-to-prevent-reply.patch
              ./patches/0008-feat-preserve-email-subject-in-reply-threading.patch
              ./patches/0009-feat-save-sent-emails-to-IMAP-Sent-folder.patch
              ./patches/0010-feat-add-channel-context-prefix-to-Telegram-messages.patch
              ./patches/0011-fix-report-accurate-capabilities-for-Claude-Code.patch
              ./patches/0012-fix-skip-permission-checks-in-Claude-Code-CLI.patch
              ./patches/0013-feat-add-swarm-gateway-endpoint.patch
              ./patches/0014-feat-sop-provider-override.patch
              ./patches/0015-feat-swarm-agentic-agent-loop.patch
              ./patches/0016-fix-canvas-websocket-subprotocol-response.patch
              ./patches/0017-fix-canvas-store-shared-between-gateway-and-channels.patch
              ./patches/0018-fix-skip-noreply-and-bounce-emails-to-prevent-error.patch
              ./patches/0019-feat-add-cross-channel-awareness-to-Telegram-contex.patch
              ./patches/0020-fix-strip-anthropic-prefix-from-model-id-in-API-cal.patch
            ];

            postPatch = ''
              cp ${./patches/xmpp.rs} src/channels/xmpp.rs
              cp ${./patches/openai_proxy.rs} src/gateway/openai_proxy.rs
              rm -rf web/dist
              ln -s ${zeroclaw-web} web/dist
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

          zeroclaw-mcp = pkgs.python3Packages.buildPythonApplication {
            pname = "zeroclaw-mcp";
            version = "0.1.0";
            pyproject = true;

            src = ./mcp-servers/zeroclaw;

            build-system = [ pkgs.python3Packages.hatchling ];
            dependencies = with pkgs.python3Packages; [
              mcp
              httpx
              slixmpp
            ];

            meta = {
              description = "MCP server bridging ZeroClaw gateway tools to Claude Code";
              mainProgram = "zeroclaw-mcp";
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
