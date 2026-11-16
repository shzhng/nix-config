{ pkgs, ... }:
{
  programs = {
    atuin.enable = true;
    bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [ batman ];
    };
    bottom.enable = true;
    btop.enable = true;
    fd.enable = true;
    fzf = {
      enable = true;
      # Atuin owns Ctrl-R for shell history; keep fzf for files/dirs only.
      historyWidget.command = "";
    };
    herdr = {
      enable = true;
      # Config is a read-only symlink; edit here, not via herdr's own
      # config commands. Reloads the running server automatically on change.
      settings = {
        onboarding = false;
        theme = {
          # Ghostty's ?997 color-scheme report follows the macOS system
          # appearance, not the terminal background, so auto_switch flips
          # herdr to latte whenever macOS is in its light phase. Ghostty is
          # pinned to mocha for both modes, so pin herdr to catppuccin too.
          name = "catppuccin";
          auto_switch = false;
          light_name = "catppuccin-latte";
          dark_name = "catppuccin";
        };
        ui = {
          # distinct glyphs per agent state instead of colour-only dots
          status_indicators = "symbols";
          show_agent_labels_on_pane_borders = true;
          toast.delivery = "terminal";
        };
        # herdr-annotate (plannotator) plugin actions; the plugin itself is
        # installed imperatively with `herdr plugin install
        # plannotator/herdr-annotate`. Keys follow its README and are free in
        # herdr's defaults (prefix+o is taken, so document review is prefix+d).
        keys.command =
          map
            (
              b:
              b
              // {
                type = "plugin_action";
                command = "annotate.${b.command}";
              }
            )
            [
              {
                key = "prefix+a";
                command = "capture";
                description = "annotate text";
              }
              {
                key = "prefix+shift+a";
                command = "copy-context";
                description = "copy annotations as context";
              }
              {
                key = "prefix+ctrl+a";
                command = "copy-archive";
                description = "copy annotations as context and archive them";
              }
              {
                key = "prefix+ctrl+v";
                command = "paste-archive";
                description = "paste annotations into the agent's prompt and archive them";
              }
              {
                key = "prefix+ctrl+s";
                command = "send-archive";
                description = "send annotations to the agent and archive them";
              }
              {
                key = "prefix+m";
                command = "manage";
                description = "manage annotations";
              }
              {
                key = "prefix+d";
                command = "open";
                description = "review documents in this folder";
              }
              {
                key = "prefix+ctrl+d";
                command = "gate";
                description = "review documents here, with Approve";
              }
              {
                key = "prefix+shift+o";
                command = "last";
                description = "review the agent's last reply";
              }
              {
                key = "prefix+ctrl+o";
                command = "last-newest";
                description = "review the agent's newest reply";
              }
              {
                key = "prefix+t";
                command = "terminal";
                description = "review this pane's recent output";
              }
              {
                key = "prefix+ctrl+r";
                command = "review";
                description = "review this repo's changes";
              }
            ];
      };
    };
    lsd.enable = true;
    mise = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };
    uv.enable = true;
    zoxide.enable = true;
  };

  home = {
    # The everyday CLI set that is not a programs.* module, shared by every
    # host that imports homeModules.cli (the Macs via home.nix, and the NixOS
    # hosts: nickel, and aluminum for its Hermes agent). Mac-only tools stay in
    # home.nix.
    packages = with pkgs; [
      nodejs
      fastfetch
      ripgrep

      # Nix
      cachix
      nil
      nixfmt
      nixd

      # Utils
      doggo
      duf
      dust
      jq

      # Database tools
      duckdb
    ];

    sessionVariables = {
      # Use bat for man pages, though we prob won't need this since
      # installed batman
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    };

    shellAliases = {
      "cat" = "bat --paging=never";
    };
  };
}
