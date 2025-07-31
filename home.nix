{ pkgs, ... }:

let
  fonts = import ./modules/fonts.nix { inherit pkgs; };
in
{
  nixpkgs.config = {
    allowUnfree = true;
  };

  imports = [
    ./modules/editors
    ./modules/git
    ./modules/shells
    ./modules/terminals
    ./modules/tools
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "shuo";
  # TODO this probably should be passed in as a parameter? and derived from username
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/shuo" else "/home/shuo";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages =
    let
      wrapped-poetry = pkgs.writeShellScriptBin "poetry" ''
        # Wrap in libraries expected by numpy etc
        export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib/
        export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ pkgs.zlib ]}:$LD_LIBRARY_PATH"
        exec ${pkgs.poetry}/bin/poetry $@
      '';
    in
    with pkgs;
    [
      # Cross-platform apps
      _1password-gui
      _1password-cli
      code-cursor
      discord
      firefox
      google-chrome
      mullvad
      slack
      spotify
      tailscale
      vscode
      zoom-us

      # Cloud host CLI tools
      azure-cli
      awscli
      hcloud

      # Development tools
      claude-code
      kubectl
      kubernetes-helm
      opentofu
      cf-terraforming

      fastfetch

      # Nix
      nixfmt-rfc-style
      nixd

      # Utils
      certbot
      devenv
      doggo
      duf
      dust
      unixODBC
      uutils-coreutils-noprefix

      # Database tools
      duckdb

      # DotNet
      dotnet-sdk

      # Elixir
      elixir
      flyctl

      # Python
      wrapped-poetry

      # Rust
      cargo
      rustc
    ]
    ++ fonts.fonts.packages;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';

    karabiner = pkgs.lib.mkIf pkgs.stdenv.isDarwin {
      target = ".config/karabiner/karabiner.json";
      source = ./config/karabiner/karabiner.json;
    };

    ssh = {
      target = ".ssh/config";
      # Add 1password agent to ssh config
      text =
        let
          _1password-agent =
            if pkgs.stdenv.isDarwin then
              "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
            else
              "~/.1password/agent.sock";
        in
        ''
          Match host * exec "test -z $SSH_CONNECTION"
            IdentityAgent "${_1password-agent}"
            ForwardAgent yes
        '';
    };
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/shuo/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  catppuccin = {
    enable = true;
    flavor = "mocha";
  };

  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;
  };
}
