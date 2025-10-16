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
  home = {
    username = "shuo";
    # TODO this probably should be passed in as a parameter? and derived from username
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/shuo" else "/home/shuo";

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
  # environment.
  # IMPORTANT: When adding/removing CLI tools, update the ~/.claude/CLAUDE.md file below
  # to keep Claude Code informed about available tools
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
      code-cursor
      discord
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
      gh
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
      jq
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

    ".claude/CLAUDE.md" = {
      # IMPORTANT: Keep this file updated when adding/removing CLI tools above
      # This helps Claude Code make better tool recommendations
      text = ''
        # Available CLI Tools

        This file documents the CLI tools available in this environment to help Claude Code make better recommendations.

        ## File Operations
        - `fd` - Fast find replacement for searching files and directories
        - `bat` - Cat replacement with syntax highlighting and paging
        - `lsd` - Modern ls replacement with icons and colors
        - `duf` - Modern df replacement for disk usage
        - `dust` - Modern du replacement for directory sizes

        ## Text Processing
        - `jq` - JSON processor for parsing and manipulating JSON data
        - `doggo` - DNS lookup utility
        - `fzf` - Fuzzy finder for interactive filtering

        ## System Monitoring
        - `bottom` (btop) - Cross-platform system monitor
        - `btop` - Resource monitor with better interface

        ## Development Tools
        - `git` - Version control with delta pager configured
        - `gh` - GitHub CLI for interacting with GitHub from the command line
        - `lazygit` - Terminal UI for git commands
        - `kubectl` - Kubernetes command line tool
        - `helm` - Kubernetes package manager
        - `opentofu` - Infrastructure as code tool
        - `cf-terraforming` - CloudFlare terraform generator

        ## Cloud Tools
        - `azure-cli` (az) - Azure command line interface
        - `awscli` (aws) - AWS command line interface
        - `hcloud` - Hetzner Cloud CLI
        - `flyctl` - Fly.io deployment tool

        ## Package Managers
        - `poetry` - Python dependency management (wrapped for library compatibility)
        - `cargo` - Rust package manager

        ## Shell Enhancement
        - `zoxide` - Smart cd command with frecency
        - `atuin` - Shell history replacement with sync
        - `starship` - Cross-shell prompt
        - `tmux` - Terminal multiplexer
        - `direnv` - Environment variable management per directory

        ## Database Tools
        - `duckdb` - Analytical SQL database

        ## Nix Tools
        - `nixfmt-rfc-style` - Nix code formatter
        - `nixd` - Nix language server

        ## System Information
        - `fastfetch` - System information display

        ## Aliases
        - `cat` -> `bat --paging=never`
        - `g` -> `git` (plus many git aliases like `ga`, `gc`, `gst`, etc.)

        ## Notes
        - All tools are installed via Nix and available in PATH
        - Many tools have enhanced configurations (e.g., git uses delta pager)
        - Shell completions are automatically configured for zsh and fish
        - Prefer these modern alternatives over traditional tools when available
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
