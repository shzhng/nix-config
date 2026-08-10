{ pkgs, ... }:

let
  # Single source of truth for agent instructions, shared across harnesses.
  # Content rules to keep it portable: describe behavior, not harness
  # features, and keep harness-specific bits in that harness's own options.
  # IMPORTANT: Keep AGENTS.md updated when adding/removing CLI tools in
  # home.nix so agents know what's available.
  agentContext = builtins.readFile ./AGENTS.md;

  # Skills in the portable SKILL.md format, shared across harnesses that
  # support them (claude-code today; opencode also has a skills option).
  agentSkills = {
    # herdr's bundled agent skill (pane control, cross-agent orchestration);
    # regenerated whenever the pinned herdr version changes
    herdr = pkgs.runCommand "herdr-skill" { } ''
      ${pkgs.lib.getExe pkgs.herdr} --skill > $out
    '';
  };
in
{
  programs.claude-code = {
    enable = true;
    context = agentContext; # -> ~/.claude/CLAUDE.md
    skills = agentSkills; # -> ~/.claude/skills/<name>/SKILL.md
  };

  # Planned harnesses — flip on when adopted. Add the package to the
  # llm-agents.nix overlay in flake.nix (alongside claude-code and herdr)
  # for daily-updated builds, and run `herdr integration install <kind>`
  # once for herdr state detection.
  #
  # programs.codex = {
  #   enable = true;
  #   custom-instructions = agentContext; # -> ~/.codex/AGENTS.md
  # };
  #
  # programs.opencode = {
  #   enable = true;
  #   context = agentContext; # -> ~/.config/opencode/AGENTS.md
  #   skills = agentSkills;
  # };
}
