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
      #   external_directory - deny secret dirs OUTSIDE the project (~/.ssh, etc.)
      #   bash               - deny env dumps + secret file reads (no catch-all)
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

          # `~` is expanded to $HOME by opencode for these patterns. No
          # catch-all here on purpose: the default `external_directory`
          # behavior ("ask", with internal temp/skill dirs allowed) is
          # already what we want, so we only add deny rules.
          external_directory = {
            "~/.ssh/**" = "deny";
            "~/.aws/**" = "deny";
            "~/.azure/**" = "deny";
            "~/.config/**" = "deny";
            "~/.gnupg/**" = "deny";
            "~/.kube/**" = "deny";
            "~/.docker/**" = "deny";
            "~/.npmrc" = "deny";
            "~/.netrc" = "deny";
            "~/.git-credentials" = "deny";
            "~/.envrc*" = "deny";
            "~/.local/share/opencode/**" = "deny";
            "~/Library/Keychains/**" = "deny";
            "~/Library/Group Containers/**" = "deny";
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
            "cat .env*" = "deny";
            "cat */.env*" = "deny";
            "cat ~/.aws/*" = "deny";
            "cat ~/.ssh/*" = "deny";
            "cat ~/.config/*" = "deny";
            "cat ~/.npmrc" = "deny";
            "cat ~/.netrc" = "deny";
            "cat ~/.git-credentials" = "deny";
            "bat .env*" = "deny";
            "bat */.env*" = "deny";
            "bat ~/.aws/*" = "deny";
            "bat ~/.ssh/*" = "deny";
            "bat ~/.config/*" = "deny";
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
