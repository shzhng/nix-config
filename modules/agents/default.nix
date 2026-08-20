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

      # Security hardening. Permission rules are matched with the LAST
      # matching rule winning, and the merged ruleset is built as
      # [ built-in defaults, agent overrides, user config ], so everything
      # here overrides the defaults. `lib.hm.dag.entryAfter` places the
      # example/template "allow" rules after the broad `.env*` denies that
      # would otherwise catch them (last match wins -> allow).
      #
      # Layers (in order of protection):
      #   read               - deny secret files INSIDE the project
      #   external_directory - ask (not deny) for secret dirs OUTSIDE the project
      #                        (~/.ssh, etc.) so legit reads are approvable
      #   bash               - deny env dumps + in-project secret file reads (no catch-all)
      #   webfetch/websearch  - "ask" (was "allow"), so the user sees every request
      #   share               - disabled, sessions never leave the machine
      settings = {
        share = "disabled";

        permission = {
          read = {
            "**/.env*" = "deny";
            "**/.envrc*" = "deny";
            "**/.netrc" = "deny";
            "**/.git-credentials" = "deny";
            "**/.npmrc" = "deny";
            "**/id_rsa*" = "deny";
            "**/id_ed25519*" = "deny";
            "**/*.pem" = "deny";
            "**/*.key" = "deny";
            "**/*.p12" = "deny";
            "**/*.pfx" = "deny";
            # example/template env files carry no secrets, so un-deny them
            "**/.env.example" = lib.hm.dag.entryAfter [ "**/.env*" ] "allow";
            "**/.env.template" = lib.hm.dag.entryAfter [ "**/.env*" ] "allow";
            "**/.envrc.example" = lib.hm.dag.entryAfter [ "**/.env*" "**/.envrc*" ] "allow";
            "**/.envrc.template" = lib.hm.dag.entryAfter [ "**/.env*" "**/.envrc*" ] "allow";
          };

          # `~` is expanded to $HOME by opencode for these patterns. Access is
          # "ask" (not flat "deny") so legitimate reads — e.g. peeking at an
          # ssh config or a repo's opencode settings — can be approved
          # once/always, while anything unexpected still prompts. The default
          # `external_directory` behavior is already "ask" for everything else,
          # so these rules just make the intent explicit.
          external_directory = {
            "~/.ssh/**" = "ask";
            "~/.aws/**" = "ask";
            "~/.azure/**" = "ask";
            "~/.config/**" = "ask";
            "~/.gnupg/**" = "ask";
            "~/.kube/**" = "ask";
            "~/.docker/**" = "ask";
            "~/.npmrc" = "ask";
            "~/.netrc" = "ask";
            "~/.git-credentials" = "ask";
            "~/.envrc*" = "ask";
            "~/.local/share/opencode/**" = "ask";
            "~/Library/Keychains/**" = "ask";
            "~/Library/Group Containers/**" = "ask";
          };

          bash = {
            "env*" = "deny";
            "printenv*" = "deny";
            "export*" = "deny";
            "set" = "deny";
            "direnv*" = "deny";
            "gh auth token*" = "deny";
            "git credential*" = "deny";
            "aws configure*" = "deny";
            "gcloud auth print-access-token*" = "deny";
            "security find-generic-password*" = "deny";
            # in-project secret files; `~/.aws`, `~/.ssh`, etc. are gated by
            # external_directory "ask" instead (no rule here, so no double prompt)
            "cat .env*" = "deny";
            "cat */.env*" = "deny";
            "bat .env*" = "deny";
            "bat */.env*" = "deny";
            # `*env.example` etc. also match nested paths like `config/.env.example`
            "cat *env.example" = lib.hm.dag.entryAfter [ "cat .env*" "cat */.env*" ] "allow";
            "cat *env.template" = lib.hm.dag.entryAfter [ "cat .env*" "cat */.env*" ] "allow";
            "cat *envrc.example" = lib.hm.dag.entryAfter [ "cat .env*" "cat */.env*" ] "allow";
            "cat *envrc.template" = lib.hm.dag.entryAfter [ "cat .env*" "cat */.env*" ] "allow";
            "bat *env.example" = lib.hm.dag.entryAfter [ "bat .env*" "bat */.env*" ] "allow";
            "bat *env.template" = lib.hm.dag.entryAfter [ "bat .env*" "bat */.env*" ] "allow";
            "bat *envrc.example" = lib.hm.dag.entryAfter [ "bat .env*" "bat */.env*" ] "allow";
            "bat *envrc.template" = lib.hm.dag.entryAfter [ "bat .env*" "bat */.env*" ] "allow";
          };

          webfetch = "ask";
          websearch = "ask";
        };
      };
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
