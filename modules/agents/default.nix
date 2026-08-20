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

        # oh-my-openagent (formerly oh-my-opencode): multi-agent harness
        # plugin (Sisyphus orchestrator etc.), fetched from npm by opencode
        # itself on startup. Its config lives in oh-my-openagent.jsonc (see
        # xdg.configFile below), where every agent is routed through
        # OpenRouter. One-time setup: `opencode auth login` -> OpenRouter.
        plugin = [ "oh-my-openagent" ];

        # default model for plain opencode agents (build/plan), also via
        # OpenRouter to match the oh-my-openagent routing
        model = "openrouter/openrouter/auto";

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

  # oh-my-openagent's own config; opencode's home-manager module has no
  # option for plugin config files, so it's linked into place directly
  xdg.configFile."opencode/oh-my-openagent.jsonc".source = ./oh-my-openagent.jsonc;

  home.packages = [ pkgs.claude-code-router ];

  home.activation.herdrIntegrations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for kind in claude codex opencode; do
      run ${lib.getExe pkgs.herdr} integration install "''$kind" || true
    done
  '';

}
