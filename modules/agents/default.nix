{ pkgs, lib, ... }:

let
  agentContext = builtins.readFile ./AGENTS.md;

  agentSkills = {
    herdr = pkgs.runCommand "herdr-skill" { } ''
      ${pkgs.lib.getExe pkgs.herdr} --skill > $out
    '';
    nix-config-sync = ./skills/nix-config-sync;
  };

  # ori launches Claude Code against OpenRouter with the main model taken from
  # its own config (e.g. openrouter/auto), but Claude Code's auto-mode
  # permission classifier pins claude-sonnet-5 via ANTHROPIC_DEFAULT_SONNET_MODEL
  # instead of the main model setting, so classifier calls (~full context, a
  # few output tokens, every turn) silently route to paid Anthropic providers
  # on OpenRouter. Defaulting the tier aliases to openrouter/auto here keeps
  # every request on the configured route; scoping it to the ori wrapper
  # (rather than home.sessionVariables) leaves direct `claude` runs against
  # Anthropic untouched. --set-default still allows per-invocation overrides.
  ori = pkgs.symlinkJoin {
    name = "ori-openrouter";
    paths = [ pkgs.ori ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/ori \
        --set-default ANTHROPIC_DEFAULT_SONNET_MODEL openrouter/auto \
        --set-default ANTHROPIC_DEFAULT_OPUS_MODEL openrouter/auto \
        --set-default ANTHROPIC_DEFAULT_HAIKU_MODEL openrouter/auto
    '';
    inherit (pkgs.ori) meta;
  };
in
{
  programs = {
    # Shared MCP server registry (~/.config/mcp/mcp.json). Servers are defined
    # once in `mcp-servers.programs` below; claude-code and opencode consume it
    # via enableMcpIntegration, codex via the /etc/codex/config.toml system
    # layer (see the codex block below and modules/darwin/default.nix).
    mcp.enable = true;

    claude-code = {
      enable = true;
      enableMcpIntegration = true;
      context = agentContext;
      skills = agentSkills;
    };
    # Codex config is layered: /etc/codex/config.toml (system) -> managed
    # -> $CODEX_HOME/config.toml (user) -> profile/project layers. The user
    # config.toml is the ONLY file Codex writes at runtime (project trust
    # levels, "don't show again" notices, personal overrides), so it must stay
    # a real writable file — if home-manager symlinks it into the read-only
    # Nix store, every trust decision fails with "failed to persist
    # config.toml".
    #
    # So this module deliberately does NOT manage config.toml (no `settings`,
    # no `enableMcpIntegration`). The pieces home-manager writes below are
    # only ever READ by Codex, never written: AGENTS.md context, skills, and
    # the openrouter.config.toml profile. MCP servers and the stable defaults
    # live in the read-only /etc/codex/config.toml system layer instead (see
    # modules/darwin/default.nix), which Codex never writes; anything set in
    # the writable user config.toml merges on top of it, so personal settings
    # always win.
    codex = {
      enable = true;
      context = agentContext;
      skills = agentSkills;

      profiles.openrouter = {
        model = "openrouter/auto";
        model_provider = "openrouter";

        model_providers.openrouter = {
          name = "OpenRouter";
          base_url = "https://openrouter.ai/api/v1";
          env_key = "OPENROUTER_API_KEY";
          wire_api = "responses";
          requires_openai_auth = false;
        };
      };
    };
    opencode = {
      enable = true;
      enableMcpIntegration = true;
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

          # MCP tool calls are permission-checked as "<server>_<tool>" against
          # a base catch-all allow rule, so without explicit entries they
          # bypass every gate above — a prompt-injected playwright navigation
          # or github write would run silently while the equivalent
          # webfetch/bash command prompts. Gate the servers with side effects;
          # context7/nixos/terraform-registry are read-only docs lookups and
          # stay on the default allow (terraform_* is gated anyway since its
          # toolset gains HCP write tools if `terraform login` is ever run).
          "github_*" = "ask";
          "playwright_*" = "ask";
          "terraform_*" = "ask";
        };
      };
    };
  };

  # MCP servers, via mcp-servers-nix's curated modules. These land in
  # programs.mcp.servers; one-off servers can be added there directly
  # (nixpkgs package via `command`, hosted via `url`, npm-only via
  # `command = "npx"` as a last resort).
  mcp-servers.programs = {
    # up-to-date library documentation
    context7 = {
      enable = true;
      # nixpkgs' build is binary-cached; mcp-servers-nix's overlay build is a
      # full pnpm build that recompiles on every nixpkgs bump
      package = pkgs.context7-mcp;
    };
    # NixOS/nixpkgs packages plus NixOS, home-manager, and nix-darwin options
    # from live data (mcp-nixos)
    nixos.enable = true;
    # browser automation / screenshots
    playwright = {
      enable = true;
      # nixpkgs' build is binary-cached; mcp-servers-nix's overlay build is not
      package = pkgs.playwright-mcp;
      # reuse the homebrew-cask Chrome (auto-updating) instead of pulling a
      # second, nixpkgs-pinned ~400MB Chrome into the store; Linux keeps the
      # module's chromium default
      executable = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
    };
    # Terraform/OpenTofu registry and provider docs
    terraform.enable = true;
    github = {
      enable = true;
      # Token is pulled from gh's keychain at server spawn (via a generated
      # wrapper script) — no secret at rest. Requires `gh auth login` once.
      passwordCommand.GITHUB_PERSONAL_ACCESS_TOKEN = [
        "gh"
        "auth"
        "token"
      ];
    };
  };

  # oh-my-openagent discovers its user config at ~/.omo/omo.jsonc; it is
  # linked into place directly because the opencode module does not manage it.
  home = {
    file.".omo/omo.jsonc".source = ./oh-my-openagent.jsonc;
    packages = [ ori ];
    activation.herdrIntegrations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      for kind in claude codex opencode; do
        run ${lib.getExe pkgs.herdr} integration install "''$kind" || true
      done
    '';
    # One-time migration: home-manager used to manage ~/.codex/config.toml as
    # a symlink into the read-only Nix store, which broke Codex's trust writes
    # ("failed to persist config.toml"). The user config.toml is now
    # intentionally unmanaged (see the codex block above), so drop the stale
    # link HM left behind; Codex recreates config.toml as a regular writable
    # file on its next write. Idempotent: only fires while the store symlink
    # exists, so a future REAL user config.toml is never touched.
    activation.removeStaleCodexConfigLink = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if [ -L "$HOME/.codex/config.toml" ] && [[ "$(readlink "$HOME/.codex/config.toml")" == /nix/store/* ]]; then
        rm -f "$HOME/.codex/config.toml"
      fi
    '';
  };

}
