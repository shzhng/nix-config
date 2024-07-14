{ ... }: {
  programs = {
    bat.enable = true;
    fzf.enable = true;
    lsd = {
      enable = true;
      enableAliases = true;
    };
    zoxide.enable = true;
    atuin.enable = true;
    btop.enable = true;
    bottom.enable = true;
  };
}