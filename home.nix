{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "shuo";
  home.homeDirectory = "/Users/shuo";

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
  home.packages = with pkgs; [

    # fonts
    fira-code
    hubot-sans
    jetbrains-mono
    monaspace
    # Only install select nerdfonts since it's huge
    (nerdfonts.override { fonts = [ "Hack" "Monaspace" ]; })
    source-code-pro

    # Cloud host CLI tools
    azure-cli
    awscli
    hcloud

    # Development tools
    kubectl
    kubernetes-helm
    opentofu
    cf-terraforming

    fastfetch

    # Utils
    doggo
    duf
    dust
    uutils-coreutils-noprefix

    # Database tools
    duckdb
  ];

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

  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    # Add in all shells I could possibly use to make sure all programs are
    # integrated well - ie. starship prompt, better cli tools' autocompletion enabled
    zsh.enable = true;
    fish = {
      enable = true;
      interactiveShellInit = ''
        ${pkgs.fastfetch}/bin/fastfetch
      '';
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    git = {
      enable = true;
      userName = "Shuo Zheng";
      userEmail = "github@shuo.dev";
      ignores = [ ".DS_Store" ];
      extraConfig = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
      };
      difftastic.enable = true;
    };

    bat.enable = true;
    fzf.enable = true;
    lsd = {
      enable = true;
      enableAliases = true;
    };
    zoxide.enable = true;
    atuin.enable = true;

    starship = {
      enable = true;
      settings = pkgs.lib.importTOML ./modules/starship/starship.toml;
    };

    wezterm = {
      enable = true;
      extraConfig = builtins.readFile ./modules/wezterm/wezterm.lua;
    };

    btop.enable = true;
    bottom.enable = true;
  };
}
