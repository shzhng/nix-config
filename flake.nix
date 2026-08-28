{
  description = "Nix/Darwin system tools flake for shzhng";

  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations. Be very careful changing this because
    # it'll impact your entire system.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";

    # Add git-hooks.nix for pre-commit hooks
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Daily-updated packages for AI coding agent tools (claude-code, herdr, etc.).
    # Replaces the nixpkgs versions via the overlay applied below.
    # Deliberately NOT following our nixpkgs: rebasing onto a different
    # nixpkgs changes every derivation hash, which misses cache.numtide.com
    # and forces source builds (codex is a huge Rust workspace).
    llm-agents.url = "github:numtide/llm-agents.nix";

    # MCP server packages + curated home-manager modules. Feeds home-manager's
    # shared programs.mcp registry; each agent consumes it via
    # enableMcpIntegration. Note: `follows` does not govern server package
    # sourcing — its HM module overlays the host nixpkgs regardless. It has no
    # binary cache of its own and some of its packages are full pnpm/npm
    # builds, so packages with nixpkgs equivalents are overridden to the
    # cached nixpkgs builds in modules/agents/default.nix.
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Fork branch carrying the ori package (OpenRouter's agent CLI) until it
    # lands upstream. Only `ori` is taken from here; everything else stays on
    # the numtide input above. Following our nixpkgs is fine for this input
    # (unlike llm-agents): ori is a prebuilt-binary fetch, so there are no
    # heavy source builds and no numtide cache to preserve.
    llm-agents-ori = {
      url = "github:shzhng/llm-agents.nix/feat/add-ori";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hermes Agent (Nous Research) — self-improving AI agent. Provides both
    # the package and a home-manager module (services.hermes-agent +
    # programs.hermes-agent). Not following our nixpkgs: it uses uv2nix
    # which is sensitive to nixpkgs versions, and has no dedicated binary
    # cache to preserve.
    hermes-agent.url = "github:NousResearch/hermes-agent";

    # OMP / oh-my-pi — terminal-based coding agent with multi-model support.
    # Provides both the package and a home-manager module (programs.omp).
    # Not following our nixpkgs: the flake uses nix-community.cachix.org
    # (already in our substituters) and has special nixpkgs handling for
    # x86_64-darwin.
    oh-my-pi.url = "github:can1357/oh-my-pi";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      home-manager,
      catppuccin,
      git-hooks,
      llm-agents,
      mcp-servers-nix,
      llm-agents-ori,
      hermes-agent,
      oh-my-pi,
    }:
    let
      homeManagerBackupModule = import ./modules/home-manager-backup.nix;

      # Home-manager modules shared by the darwin hosts and the standalone
      # Linux homeConfiguration — one list so the two can't silently diverge.
      sharedHomeModules = [
        ./home.nix
        catppuccin.homeModules.catppuccin
        mcp-servers-nix.homeManagerModules.default
        hermes-agent.homeManagerModules.default
        oh-my-pi.homeManagerModules.default
      ];

      # Define shared tap configuration
      brewTaps = {
        "homebrew/homebrew-core" = homebrew-core;
        "homebrew/homebrew-cask" = homebrew-cask;
      };

      # Get just the tap names (for nix-darwin's homebrew.taps)
      brewTapNames = builtins.attrNames brewTaps;

      # Shared configuration for all your macOS systems
      darwinCommonModules = [
        # catppuccin.nixosModules.catppuccin TODO only use this with NixOS
        ./modules/darwin
        homeManagerBackupModule
        # Take agent CLI tools from llm-agents.nix (daily updates) instead of
        # the (often lagging) nixpkgs versions. hermes-agent and omp are
        # sourced from their own upstream flakes (which also provide
        # home-manager modules) — see the flake inputs above.
        {
          nixpkgs.overlays = [
            (_final: prev: {
              inherit (llm-agents.packages.${prev.stdenv.hostPlatform.system})
                claude-code
                codex
                herdr
                opencode
                ;
              inherit (llm-agents-ori.packages.${prev.stdenv.hostPlatform.system})
                ori
                ;
            })
          ];
        }
        home-manager.darwinModules.home-manager
        {
          # Add this configuration block to allow broken packages
          # nixpkgs.config.allowBroken = true;

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            verbose = true;
            extraSpecialArgs = {
              username = "shuo";
            };
            users.shuo = {
              imports = sharedHomeModules;
            };
          };

          # Optionally, use home-manager.extraSpecialArgs to pass
          # arguments to home.nix
        }

        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "shuo";

            # Optional: Declarative tap management - using shared tap configuration
            taps = brewTaps;

            # Optional: Enable fully-declarative tap management
            #
            # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
            mutableTaps = false;

            autoMigrate = true;
          };
        }

        # Pass tap names to darwin module for homebrew.taps
        {
          homebrew.taps = brewTapNames;
        }
      ];

      # Create pre-commit hooks configuration
      # This enables automatic formatting of Nix files before each commit
      # To install hooks, run: nix run .#install-git-hooks
      # The hooks are configured to use nixfmt to format all .nix files
      # A .pre-commit-config.yaml file will be generated (and git-ignored)
      systems = [
        "aarch64-darwin"
        # x86_64-darwin is not included due to catppuccin themes requiring ARM builds
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;

      # A host = shared modules + its profile under ./hosts.
      # Keys match each machine's hostname so a bare
      # `sudo darwin-rebuild switch --flake .` resolves automatically.
      mkDarwinHost =
        hostModule:
        nix-darwin.lib.darwinSystem {
          modules = darwinCommonModules ++ [ hostModule ];
        };
    in
    {
      darwinModules.home-manager-backup = homeManagerBackupModule;
      nixosModules.home-manager-backup = homeManagerBackupModule;

      # Build darwin flake using:
      # `nix run nix-darwin -- switch --flake .`
      # Switch with:
      # `sudo darwin-rebuild switch --flake .`
      darwinConfigurations = {
        # Personal MacBook Pro
        Shuos-MacBook-Pro = mkDarwinHost ./hosts/shuos-macbook-pro;

        # Lumaril work MacBook Pro
        Shuos-MacBook-Pro-Lumaril = mkDarwinHost ./hosts/shuos-macbook-pro-lumaril;
      };

      # Expose the package set, including overlays, for convenience.
      # We can just reference one configuration as the package set is the same for both
      darwinPackages = self.darwinConfigurations.Shuos-MacBook-Pro.pkgs;

      # Add pre-commit hooks check
      # This configures the git pre-commit hooks to run nixfmt
      # on all Nix files in the repository before each commit
      checks = forAllSystems (system: {
        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          # Mirror the CI lint job (nixfmt + statix + deadnix) so the same
          # checks run both locally and in CI.
          hooks = {
            nixfmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;
          };
        };
      });

      # This allows running: nix run .#install-git-hooks
      # Running this command will install the git pre-commit hooks
      # These hooks will automatically format Nix files when committing
      apps = forAllSystems (system: {
        install-git-hooks = {
          type = "app";
          program = toString (
            nixpkgs.legacyPackages.${system}.writeShellScript "install-git-hooks" ''
              ${self.checks.${system}.pre-commit-check.shellHook}

              # Install a post-checkout hook so that creating/switching a
              # worktree auto-installs git-hooks.nix's pre-commit hooks and
              # .pre-commit-config.yaml there (the generated config is
              # git-ignored, so worktrees don't inherit it). core.hooksPath is
              # set in the shared config, so this hook fires in every worktree;
              # install-git-hooks is idempotent, so re-running is cheap.
              hooks_dir="$(git rev-parse --git-path hooks)"
              mkdir -p "$hooks_dir"
              post_checkout="$hooks_dir/post-checkout"
              if [ ! -x "$post_checkout" ]; then
                cat > "$post_checkout" <<'HOOK'
              #!/usr/bin/env bash
              set -e
              toplevel="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
              if command -v nix >/dev/null 2>&1; then
                nix run "$toplevel"#install-git-hooks >/dev/null 2>&1 || true
              fi
              HOOK
                chmod +x "$post_checkout"
              fi
              echo "Git hooks installed successfully!"
            ''
          );
        };
      });

      # To be used as standalone when not on MacOS or NixOS
      # Initalize with:
      # `nix run home-manager -- init --switch`
      # Switch with:
      # `home-manager switch --flake .#shuo`
      homeConfigurations.shuo = home-manager.lib.homeManagerConfiguration {
        # TODO make this configurable
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {
          username = "shuo";
        };
        modules = sharedHomeModules;
      };
    };

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
      # Serves the whiskers cargo-vendor FOD, letting CI avoid crates.io
      # downloads that GitHub-hosted runners get 403'd on.
      "https://catppuccin.cachix.org"
      # numtide cache serving llm-agents.nix builds (herdr)
      "https://cache.numtide.com"
      # Personal cache: CI pushes built system closures here; both machines
      # and later CI runs substitute from it.
      "https://shzhng.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "shzhng.cachix.org-1:qLS1ho8pcjo0IbhSiwc66NzdLWk6Mcug/+RXO3SkR2o="
    ];
  };
}
