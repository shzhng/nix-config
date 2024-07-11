{ pkgs, ... }: {
  # Provision my user account.
  users.users = {
    shuo = {
      home = "/Users/shuo";
      # This is really just for setting $SHELL, rather than `chsh` your user
      # Maybe a fix incoming?: https://github.com/LnL7/nix-darwin/issues/811
      shell = pkgs.fish;
    };
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
      "babashka/brew"
      "borkdude/brew"
      "clojure-lsp/brew"
      "clojure/tools"
      "cloudflare/cloudflare"
      "d12frosted/emacs-plus"
      "derailed/k9s"
      "hashicorp/tap"
      "homebrew/bundle"
      "homebrew/cask-drivers"
      "homebrew/cask-versions"
      "homebrew/services"
      "jeffreywildman/virt-manager"
      "pluralsh/plural"
      "railwaycat/emacsmacport"
      "twilio/brew"
    ];

    brews = [
      "plural"
      "tmux"
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
      "kitty"
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

    masApps = {
    };
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Enable Touch ID for sudo, instead of entering password.
  security.pam.enableSudoTouchIdAuth = true;
}