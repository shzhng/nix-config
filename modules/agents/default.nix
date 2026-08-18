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

  # Codex reads its OpenRouter key from the environment (env_key above), but
  # exporting it into every shell would hand it to every process. Instead,
  # wrap the binary to pull opencode's runtime key from its credential store
  # at launch — scoped to codex processes, read fresh each run (rotation via
  # `nix run ~/git/shzhng/infrastructure#sync-keys` needs no rebuild), and
  # never in the nix store. An already-set OPENROUTER_API_KEY wins, so a
  # deliberate override still works.
  codexOpenrouterWrapper = pkgs.writeShellScript "codex-openrouter-wrapper" ''
    auth="$HOME/.local/share/opencode/auth.json"
    if [ -z "''${OPENROUTER_API_KEY:-}" ] && [ -f "$auth" ]; then
      key="$(${lib.getExe pkgs.jq} -r '.openrouter.key // empty' "$auth")"
      [ -n "$key" ] && export OPENROUTER_API_KEY="$key"
    fi
    exec ${pkgs.codex}/bin/codex "$@"
  '';

  codexWithOpenrouterKey = pkgs.symlinkJoin {
    # keep the version in the name: the codex module version-gates features
    # via lib.getVersion on this package
    name = "codex-${lib.getVersion pkgs.codex}";
    paths = [ pkgs.codex ];
    postBuild = ''
      rm "$out/bin/codex"
      ln -s ${codexOpenrouterWrapper} "$out/bin/codex"
    '';
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
      package = codexWithOpenrouterKey;
      context = agentContext; # -> $CODEX_HOME/AGENTS.md
      skills = agentSkills;
      # OpenRouter via `codex --profile openrouter`; the default profile
      # keeps the ChatGPT login. The key comes from OPENROUTER_API_KEY,
      # injected by the wrapper above.
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
