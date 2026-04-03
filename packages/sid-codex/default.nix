{ pkgs }:
let
  agentsFile = pkgs.writeTextDir "share/sid-codex/AGENTS.md" (builtins.readFile ./AGENTS.md);
  launcher = pkgs.writeShellScriptBin "sid-codex" ''
    exec ${pkgs.codex}/bin/codex "$@"
  '';
in
pkgs.symlinkJoin {
  name = "sid-codex";
  paths = [
    agentsFile
    launcher
  ];
}
