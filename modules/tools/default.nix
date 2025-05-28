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
    fzf.enable = true;
    lsd.enable = true;
    zoxide.enable = true;
  };

  home = {
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
