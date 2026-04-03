{ sidPackageFor }:
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.sid-codex;
in
{
  options.programs.sid-codex = {
    enable = lib.mkEnableOption "Sid-flavored Codex persona";

    package = lib.mkOption {
      type = lib.types.package;
      default = sidPackageFor pkgs.system;
      defaultText = lib.literalExpression "inputs.sid.packages.${pkgs.system}.sid-codex";
      description = "Package that provides the Sid Codex launcher and bundled AGENTS.md.";
    };

    installCodexPackage = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install pkgs.codex into the user's profile in addition to sid-codex.";
    };

    agentsFileTarget = lib.mkOption {
      type = lib.types.str;
      default = "AGENTS.md";
      description = "Home-relative path where the Sid AGENTS.md file should be installed.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [ cfg.package ]
      ++ lib.optional cfg.installCodexPackage pkgs.codex;

    home.file.${cfg.agentsFileTarget}.source = "${cfg.package}/share/sid-codex/AGENTS.md";
  };
}
