{
  pkgs,
  username,
  flakeSelf ? null,
  ...
}:

let
  flakeRef =
    if flakeSelf != null && flakeSelf ? outPath then "${flakeSelf}" else "~/git/shzhng/nix-config";
in

let
  fonts = import ./modules/fonts.nix { inherit pkgs; };
in
{
  # Note: nixpkgs.config is set in modules/darwin (allowUnfree) when using
  # useGlobalPkgs. Setting it here would cause a warning.

  imports = [
    ./modules/agents
    ./modules/editors
    ./modules/git
    ./modules/shells
    ./modules/terminals
    ./modules/tools
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home = {
    inherit username;
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "23.11"; # Please read the comment before changing.
  };

  # The home.packages option allows you to install Nix packages into your
  # environment. Machine-specific packages live in hosts/<hostname>/home.nix.
  # IMPORTANT: When adding/removing CLI tools, update modules/agents/AGENTS.md
  # to keep coding agents informed about available tools
  home.packages =
    with pkgs;
    [
      # Cloud host CLI tools
      azure-cli
      awscli2
      hcloud

      # Development tools
      gh
      nodejs
      kubectl
      kubernetes-helm
      opentofu
      cf-terraforming

      fastfetch
      ripgrep

      # Nix
      cachix
      nil
      nixfmt
      nixd

      # Utils
      certbot
      doggo
      duf
      dust
      jq
      unixodbc
      uutils-coreutils-noprefix

      # Database tools
      duckdb

      # Elixir
      beamPackages.elixir
      flyctl

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
      force = true; # Overwrite without backup to avoid .backup file conflicts
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
          Include ~/.ssh/1Password/config

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

  home.shellAliases = pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
    # Rebuild the system, pushing locally-built store paths to the personal
    # cachix. post-build-hook mode only ever uploads paths *built* on this
    # machine (never substituted downloads), so it cannot blow the quota.
    # Requires one-time setup per machine:
    #   cachix authtoken <token>
    #   trusted-users = root shuo   (in /etc/nix/nix.custom.conf)
    rebuild = "cachix watch-exec --watch-mode post-build-hook shzhng -- darwin-rebuild build --flake ${flakeRef} && sudo darwin-rebuild switch --flake ${flakeRef}";
  };

  catppuccin = {
    enable = true;
    # Opt in to catppuccin/nix's upcoming behavior early: autoEnable themes
    # every supported program; enable acts as the global toggle.
    autoEnable = true;
    flavor = "mocha";
  };

  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;
  };
}
