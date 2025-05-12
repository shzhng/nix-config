{ pkgs, ... }: {
  programs = {
    atuin.enable = true;
    bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [ batman ];
    };
    bottom.enable = true;
    btop.enable = true;
    fd.enable = true;
    fzf.enable = true;
    lsd.enable = true;
    zoxide.enable = true;
  };

  home = {
    # Install `vivid` to generate colors for `ls` (and `lsd`)
    # TODO: Remove this once we have a better way to handle colors, maybe via programs.lsd.colors
    packages = [ pkgs.vivid ];
    sessionVariables = {
      # Use bat for man pages, though we prob won't need this since
      # installed batman
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      LS_COLORS = "$(vivid generate catppuccin-mocha)";
    };

    shellAliases = { "cat" = "bat --paging=never"; };
  };
}
