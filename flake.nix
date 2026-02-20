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

            # Default features: hardware (nusb) + channel-matrix (matrix-sdk)
            # Code isn't properly feature-gated, so build with defaults
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
