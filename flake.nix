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
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      home-manager,
      catppuccin,
    }:
    let
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
        home-manager.darwinModules.home-manager
        {
          # Add this configuration block to allow broken packages
          # nixpkgs.config.allowBroken = true;

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            verbose = true;
            users.shuo = {
              imports = [
                ./home.nix
                catppuccin.homeManagerModules.catppuccin
              ];
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

        {
          # Overlay for karabiner-elements
          # https://github.com/LnL7/nix-darwin/issues/811
          nixpkgs.overlays = [
            (self: super: {
              karabiner-elements = super.karabiner-elements.overrideAttrs (old: {
                version = "14.13.0";
                src = super.fetchurl {
                  inherit (old.src) url;
                  hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw=";
                };
              });
            })
          ];
        }
      ];
    in
    {
      # Build darwin flake using:
      # `nix run nix-darwin -- switch --flake .`
      # Switch with:
      # `darwin-rebuild switch --flake .#Shuos-Macbook-Air`
      darwinConfigurations = {
        # Configuration for MacBook Air
        Shuos-Macbook-Air = nix-darwin.lib.darwinSystem {
          modules = darwinCommonModules;
        };

        # Configuration for MacBook Pro - using the same modules
        Shuos-MacBook-Pro = nix-darwin.lib.darwinSystem {
          modules = darwinCommonModules;
        };
      };

      # Expose the package set, including overlays, for convenience.
      # We can just reference one configuration as the package set is the same for both
      darwinPackages = self.darwinConfigurations.Shuos-MacBook-Pro.pkgs;

      # To be used as standalone when not on MacOS or NixOS
      # Initalize with:
      # `nix run home-manager -- init --switch`
      # Switch with:
      # `home-manager switch --flake .#shuo`
      homeConfigurations.shuo = home-manager.lib.homeManagerConfiguration {
        # TODO make this configurable
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./home.nix
          catppuccin.homeManagerModules.catppuccin
        ];
      };
    };

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
}
