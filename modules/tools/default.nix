{ ... }: {
  programs = {
    atuin.enable = true;
    bat.enable = true;
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
}