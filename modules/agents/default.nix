{ pkgs, lib, ... }:

let
  agentContext = builtins.readFile ./AGENTS.md;

  agentSkills = {
    herdr = pkgs.runCommand "herdr-skill" { } ''
      ${pkgs.lib.getExe pkgs.herdr} --skill > $out
    '';
    nix-config-sync = ./skills/nix-config-sync;
  };
in
{
  programs = {
    claude-code = {
      enable = true;
      context = agentContext;
      skills = agentSkills;
    };
    codex = {
      enable = true;
      context = agentContext;
      skills = agentSkills;
    };
    opencode = {
      enable = true;
      context = agentContext;
      skills = agentSkills;
    };
  };

  home.packages = [ pkgs.claude-code-router ];

  home.activation.herdrIntegrations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for kind in claude codex opencode; do
      run ${lib.getExe pkgs.herdr} integration install "''$kind" || true
    done
  '';

}
