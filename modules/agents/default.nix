{ pkgs, lib, ... }:

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
    # Repo maintenance procedure: fast-forward main, relocate drift, prune
    # merged worktrees.
    nix-config-sync = ./skills/nix-config-sync;
  };

  # OpenRouter provider stanza for codex, shared between the base config and
  # the openrouter profile (codex profile files are standalone overlays, so
  # the provider must be defined in both).
  codexOpenrouterProvider = {
    name = "OpenRouter";
    base_url = "https://openrouter.ai/api/v1";
    env_key = "OPENROUTER_API_KEY";
    wire_api = "chat";
  };
in
{
  # Packages come from the llm-agents.nix overlay in flake.nix. Run
  # `herdr integration install <kind>` once per machine for herdr state
  # detection.
  programs = {
    claude-code = {
      enable = true;
      context = agentContext; # -> ~/.claude/CLAUDE.md
      skills = agentSkills; # -> ~/.claude/skills/<name>/SKILL.md
    };

    codex = {
      enable = true;
      context = agentContext; # -> $CODEX_HOME/AGENTS.md
      skills = agentSkills;
      # OpenRouter via `codex --profile openrouter`; the default profile
      # keeps the ChatGPT login. The key comes from OPENROUTER_API_KEY
      # (see zsh.envExtra below).
      settings.model_providers.openrouter = codexOpenrouterProvider;
      profiles.openrouter = {
        # OpenRouter's meta-router picks a model per request; override per
        # run with `codex -p openrouter -m <model>` (openrouter/pareto-code
        # is the coding-tuned alternative).
        model = "openrouter/auto";
        model_provider = "openrouter";
        model_providers.openrouter = codexOpenrouterProvider;
      };
    };

    opencode = {
      enable = true;
      context = agentContext; # -> ~/.config/opencode/AGENTS.md
      skills = agentSkills;
    };

    # Codex reads its OpenRouter key from the environment (env_key above).
    # Reuses opencode's runtime key from its credential store, which
    # `nix run ~/git/shzhng/infrastructure#sync-keys` keeps fresh — no
    # second copy to rotate. Caveat: inside the infrastructure repo, direnv
    # overrides this with the management key, which cannot call models.
    zsh.envExtra = ''
      if [ -f "$HOME/.local/share/opencode/auth.json" ]; then
        OPENROUTER_API_KEY="$(${lib.getExe pkgs.jq} -r '.openrouter.key // empty' "$HOME/.local/share/opencode/auth.json")"
        [ -n "$OPENROUTER_API_KEY" ] && export OPENROUTER_API_KEY
      fi
    '';
  };

  # herdr agent-state integrations (lifecycle hooks per harness). The hook
  # files are version-coupled to the herdr binary and herdr's installer also
  # merges into mutable state (e.g. ~/.claude/settings.json), so install them
  # idempotently from the pinned binary on every activation instead of
  # managing the files declaratively.
  home.activation.herdrIntegrations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for kind in claude codex opencode; do
      run ${lib.getExe pkgs.herdr} integration install "$kind" || true
    done
  '';
}
