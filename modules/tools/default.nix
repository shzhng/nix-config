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
    lsd = {
      enable = true;
      enableAliases = true;
    };
    zoxide.enable = true;
  };

  home.sessionVariables = {
    # Use bat for man pages
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
  };

  home.shellAliases = {
    "cat" = "bat --paging=never";
  };
}
