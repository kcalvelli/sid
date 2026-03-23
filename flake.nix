{
  description = "Sid — cynical Gen X AI agent on ZeroClaw";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zeroclaw = {
      url = "github:zeroclaw-labs/zeroclaw/v0.5.9";
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

          zeroclaw-web = pkgs.buildNpmPackage {
            pname = "zeroclaw-web";
            version = "0.5.9";
            src = zeroclaw;
            sourceRoot = "source/web";
            npmDepsHash = "sha256-4+raDJ7+w+RpdeZs2PJL10IWzfoT5B3EpOxsLUnlrRc=";
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
            version = "0.5.9";
            src = zeroclaw;

            cargoHash = "sha256-cdlD2GEOZTuOA/JeDGFokTVRZ2aozpuIGJwlDiiPNmE=";

            buildFeatures = [ "memory-postgres" ];

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
            ];

            postPatch = ''
              cp ${./patches/xmpp.rs} src/channels/xmpp.rs
              cp ${./patches/openai_proxy.rs} src/gateway/openai_proxy.rs
              mkdir -p web
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

          sid-dashboard = pkgs.python3Packages.buildPythonApplication {
            pname = "sid-dashboard";
            version = "0.1.0";
            pyproject = true;

            src = ./dashboard;

            build-system = [ pkgs.python3Packages.hatchling ];
            dependencies = with pkgs.python3Packages; [
              httpx
            ];

            meta = {
              description = "Web dashboard for Sid AI agent";
              mainProgram = "sid-dashboard";
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
