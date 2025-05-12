{
  description = "Nix/Darwin system tools flake for shzhng";

  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations. Be very careful changing this because
    # it'll impact your entire system.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";

    # Remove the nixpkgs override from ghostty
    ghostty.url = "github:mitchellh/ghostty";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager
    , catppuccin, ghostty }: {
      # Build darwin flake using:
      # `nix run nix-darwin -- switch --flake .`
      # Switch with:
      # `darwin-rebuild switch --flake .#Shuos-Macbook-Air`
      darwinConfigurations.Shuos-Macbook-Air = nix-darwin.lib.darwinSystem {
        modules = [
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
              extraSpecialArgs = { inherit ghostty; };
              users.shuo = {
                imports =
                  [ ./home.nix catppuccin.homeManagerModules.catppuccin ];
              };
            };

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
          {
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
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations.Shuos-Macbook-Air.pkgs;

      # To be used as standalone when not on MacOS or NixOS
      # Initalize with:
      # `nix run home-manager -- init --switch`
      # Switch with:
      # `home-manager switch --flake .#shuo`
      homeConfigurations.shuo = home-manager.lib.homeManagerConfiguration {
        # TODO make this configurable
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./home.nix catppuccin.homeManagerModules.catppuccin ];
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
