{ pkgs, ... }:
{
  # Provision my user account.
  users.users.shuo = {
    home = "/Users/shuo";
    description = "Shuo Zheng";
    shell = pkgs.fish;
  };

  # "https://github.com/nix-darwin/nix-darwin/issues/902"
  launchd.user.agents.raycast = {
    serviceConfig.ProgramArguments = [ "/Applications/Nix Apps/Raycast.app/Contents/MacOS/Raycast" ];
    serviceConfig.RunAtLoad = true;
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs = {
    zsh = {
      enable = true; # default shell on catalina
      shellInit = ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
      '';
    };
    fish = {
      enable = true;
      loginShellInit = ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
      '';
    };

    # Include this to make 1password work, even though it's installed via home-manager
    # See "https://github.com/nix-darwin/nix-darwin/pull/1438"
    _1password-gui.enable = true;
    _1password.enable = true;
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment = {
    systemPackages = with pkgs; [
      vim
      bat
      fd
      fzf
      lsd
      git

      # Mac-specific apps
      raycast
      teams

      docker
      colima
    ];

    # Set shells that will be available to users.
    shells = with pkgs; [
      zsh
      fish
    ];
  };

  homebrew = {
    enable = true;
    # Uninstall brews and cleanup casks files if we remove packages here
    onActivation = {
      cleanup = "zap";
      upgrade = true;
      autoUpdate = true;
    };

    brews = [ ];

    casks = [
      "astro-command-center"
      "figma"
      # TODO Broken, investigate later
      # "figma-agent"
      "ghostty"
      "google-drive"
      "hiddenbar"
      "ledger-live"
      "logitech-g-hub"
      "microsoft-auto-update"
      "microsoft-office"
      "moonlight"
      # "morgen"
      # "mullvadvpn"
      "plex"
      "steam"
    ];

    masApps = {
      "1Password for Safari" = 1569813296;
    };
  };

  # Auto upgrade nix package and the daemon service.
  services = {
    # TODO: config via home manager, really just for the caps = esc/ctrl mapping
    karabiner-elements = {
      enable = true;
      # "https://github.com/nix-darwin/nix-darwin/issues/1041"
      package = pkgs.karabiner-elements.overrideAttrs (old: {
        version = "14.13.0";

        src = pkgs.fetchurl {
          inherit (old.src) url;
          hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw=";
        };

        dontFixup = true;
      });
    };

    # We explicitly don't use tailscaled + tailscale cli in favor of the
    # standalone UI version, installed via homebrew cask.
    tailscale.enable = true;

    # TODO temporarily disable sketchybar
    # sketchybar = {
    #   enable = true;
    #   extraPackages = [ pkgs.jq ];
    #   config = builtins.readFile ../../config/sketchybar/sketchybarrc;
    # };
    skhd = {
      enable = false;
      skhdConfig = builtins.readFile ../../config/skhd/skhdrc;
    };
    yabai = {
      enable = false;
      config = {
        layout = "bsp";
        top_padding = 10;
        bottom_padding = 10;
        left_padding = 10;
        right_padding = 10;
        window_gap = 10;
      };
    };
  };

  networking = {
    knownNetworkServices = [
      "Wi-Fi"
      "Thunderbolt Bridge"
      "iPhone USB"
      "Tailscale"
    ];
  };

  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  system = {
    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 4;

    # Following line should allow us to avoid a logout/login cycle when rebuilding
    # activationScripts.postUserActivation.text = ''
    #   /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    # '';

    primaryUser = "shuo";

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    defaults = {
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.2;
        orientation = "bottom";
      };

      loginwindow = {
        GuestEnabled = false;
        # If I'm logged in, require password to shutdown/poweroff/restart
        ShutDownDisabledWhileLoggedIn = true;
        PowerOffDisabledWhileLoggedIn = true;
        RestartDisabledWhileLoggedIn = true;
      };

      NSGlobalDomain = {
        _HIHideMenuBar = false;
        AppleShowScrollBars = "Always";
        AppleShowAllExtensions = true;
        # Reverse scroll direction
        "com.apple.swipescrolldirection" = false;
      };

      controlcenter = {
        BatteryShowPercentage = true;
      };

      menuExtraClock = {
        ShowSeconds = true;
      };

      CustomUserPreferences = {
        # Use this to set arbitrary custom preferences not yet supported by nix-darwin
        # See https://github.com/LnL7/nix-darwin/blob/master/modules/system/defaults/CustomPreferences.nix
        # and https://medium.com/@zmre/nix-darwin-quick-tip-activate-your-preferences-f69942a93236
        "com.apple.symbolichotkeys.AppleSymbolicHotKeys" = {
          "64" = {
            enabled = true;
            value = {
              parameters = [
                32
                49
                524288
              ];
              type = "standard";
            };
          };
        };
      };
    };
  };

  nix = {
    # Let determinate handle nix management. See https://determinate.systems/posts/nix-darwin-updates/
    enable = false;

    # nix.package = pkgs.nix;

    # Necessary for using flakes on this system.
    settings = {
      trusted-users = [
        "root"
        "shuo"
      ];
    };
    #gc = {
    #  automatic = true;
    #  options = "--delete-older-than 7d";
    #};
  };

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Allow installing proprietary apps such as 1Password and Chrome
  nixpkgs.config.allowUnfree = true;

  # Enable Touch ID for sudo, instead of entering password.
  security.pam.services.sudo_local.touchIdAuth = true;
}
