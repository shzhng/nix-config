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
