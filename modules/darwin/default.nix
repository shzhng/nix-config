{ pkgs, ... }: {
  # Provision my user account.
  users.users.shuo = {
    home = "/Users/shuo";
    description = "Shuo Zheng";
    # This is really just for setting $SHELL, rather than `chsh` your user
    # Maybe a fix incoming?: https://github.com/LnL7/nix-darwin/issues/811
    shell = pkgs.fish;
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina
  programs.fish.enable = true;

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
    ];

    # Set shells that will be available to users.
    shells = with pkgs; [ zsh fish ];
  };

  homebrew = {
    enable = true;
    # Uninstall brews and cleanup casks files if we remove packages here
    onActivation.cleanup = "zap";

    taps = [
      "1password/tap"
      "pluralsh/plural"
    ];

    brews = [
      "plural"
    ];

    casks = [
      "1password"
      "1password-cli"
      "alfred"
      "azure-data-studio"
      "calibre"
      "cursor"
      "discord"
      "figma"
      "figma-agent"
      "firefox"
      "flipper"
      "google-chrome"
      "google-drive"
      "karabiner-elements"
      "microsoft-auto-update"
      "microsoft-office"
      "microsoft-teams"
      "mullvadvpn"
      "plex"
      "slack"
      "spotify"
      "tailscale"
      "vlc"
      "visual-studio-code"
      "wechat"
      "wezterm"
      "whatsapp"
      "zoom"
    ];

    masApps = { };
  };

  # Auto upgrade nix package and the daemon service.
  services = {
    nix-daemon.enable = true;

    # We explicitly don't use tailscaled + tailscale cli in favor of the
    # standalone UI version, installed via homebrew cask.
    tailscale.enable = false;

    # TODO temporarily disable sketchybar while
    # sketchybar = {
    #   enable = true;
    #   extraPackages = [ pkgs.jq ];
    #   config = builtins.readFile ../../config/sketchybar/sketchybarrc;
    # };
    skhd = {
      enable = true;
      skhdConfig = builtins.readFile ../../config/skhd/skhdrc;
    };
    yabai = {
      enable = true;
      config = {
        layout = "float";
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
    activationScripts.postUserActivation.text = ''
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

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
      };

      CustomUserPreferences = {
        # Use this to set arbitrary custom preferences not yet supported by nix-darwin
        # See https://github.com/LnL7/nix-darwin/blob/master/modules/system/defaults/CustomPreferences.nix
        # and https://medium.com/@zmre/nix-darwin-quick-tip-activate-your-preferences-f69942a93236
      };
    };
  };

  nix = {
    # nix.package = pkgs.nix;

    # Necessary for using flakes on this system.
    settings.experimental-features = "nix-command flakes";
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Allow installing proprietary apps such as 1Password and Chrome
  nixpkgs.config.allowUnfree = true;

  # Enable Touch ID for sudo, instead of entering password.
  security.pam.enableSudoTouchIdAuth = true;
}