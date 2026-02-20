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

            # Upstream HEAD has two broken declarations:
            # 1. `futures` removed from [dependencies] but still used in code
            # 2. Duplicate `chat` method in reliable.rs (bad merge)
            postPatch = ''
              # 1. Add futures back as a dependency
              sed -i '/^futures-util/a futures = "0.3"' Cargo.toml

              # 2. Remove duplicate chat() in reliable.rs (bad merge)
              ${pkgs.python3}/bin/python3 -c "
              with open('src/providers/reliable.rs', 'r') as f:
                  lines = f.read().split('\n')
              chat_starts = [i for i, l in enumerate(lines) if l.strip() == 'async fn chat(']
              if len(chat_starts) >= 2:
                  start = chat_starts[1]
                  depth = 0
                  found_open = False
                  end = start
                  for i in range(start, len(lines)):
                      depth += lines[i].count('{') - lines[i].count('}')
                      if depth > 0:
                          found_open = True
                      if found_open and depth == 0:
                          end = i
                          break
                  lines = lines[:start] + lines[end+1:]
                  with open('src/providers/reliable.rs', 'w') as f:
                      f.write('\n'.join(lines))
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
