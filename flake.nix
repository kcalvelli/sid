{
  description = "Sid — cynical Gen X AI agent on ZeroClaw";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zeroclaw-nix = {
      url = "github:kcalvelli/zeroclaw-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zeroclaw-nix, agenix, ... }:
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
          sid-codex = pkgs.callPackage ./packages/sid-codex { };

          zeroclaw-web = zeroclaw-nix.packages.${system}.zeroclaw-web.override {
            pwaOverlay = ./web/pwa;
          };

          zeroclaw = zeroclaw-nix.packages.${system}.zeroclaw.override {
            zeroclaw-web = self.packages.${system}.zeroclaw-web;
          };

          zeroclaw-desktop = zeroclaw-nix.packages.${system}.zeroclaw-desktop;

          default = self.packages.${system}.zeroclaw;
        });

      homeManagerModules.sid-codex = import ./modules/home-manager {
        sidPackageFor = system: self.packages.${system}.sid-codex;
      };

      nixosModules.default = { pkgs, ... }: {
        imports = [
          agenix.nixosModules.default
          zeroclaw-nix.nixosModules.default
          ./modules/nixos
        ];
      };
    };
}
