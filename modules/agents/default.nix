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

  # OpenRouter for codex is delivered entirely through codex's runtime config
  # layer (`-c` flags) plus an env var — deliberately NOT via
  # programs.codex.settings/profiles. Managed files under CODEX_HOME are
  # read-only store symlinks, which breaks codex's own writes there (it
  # persists directory-trust decisions and TUI settings into the active
  # config file); leaving ~/.codex/config.toml unmanaged lets codex own
  # those. Plain `codex` stays stock (ChatGPT login); `codex-or` routes via
  # OpenRouter.
  codexOpenrouterProvider = {
    name = "OpenRouter";
    base_url = "https://openrouter.ai/api/v1";
    env_key = "OPENROUTER_API_KEY";
    # codex 0.147+ dropped the chat wire API; OpenRouter serves /responses.
    wire_api = "responses";
  };

  codexOrFlags = lib.concatStringsSep " " (
    [
      "-c 'model_provider=\"openrouter\"'"
      # OpenRouter's meta-router picks a model per request; override per run
      # with `codex-or -m <model>` (openrouter/pareto-code is the
      # coding-tuned alternative).
      "-c 'model=\"openrouter/auto\"'"
    ]
    ++ lib.mapAttrsToList (
      k: v: "-c 'model_providers.openrouter.${k}=\"${v}\"'"
    ) codexOpenrouterProvider
  );

  # The key is codex's own provisioned OpenRouter key, written by
  # `nix run ~/git/shzhng/infrastructure#sync-keys` — read fresh each run
  # (rotation needs no rebuild), never in the nix store, and visible only to
  # this process. An already-set OPENROUTER_API_KEY wins, so a deliberate
  # override still works.
  codexOr = pkgs.writeShellScriptBin "codex-or" ''
    keyfile="$HOME/.local/share/openrouter/codex.key"
    if [ -z "''${OPENROUTER_API_KEY:-}" ] && [ -f "$keyfile" ]; then
      key="$(cat "$keyfile")"
      [ -n "$key" ] && export OPENROUTER_API_KEY="$key"
    fi
    exec ${pkgs.codex}/bin/codex ${codexOrFlags} "$@"
  '';
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
      # No settings/profiles here on purpose — see codexOr above.
    };

    opencode = {
      enable = true;
      context = agentContext; # -> ~/.config/opencode/AGENTS.md
      skills = agentSkills;
    };
  };

  home.packages = [ codexOr ];

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
