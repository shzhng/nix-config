{ pkgs, ... }:
{
  imports = [
    ./zed
  ];

  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };
  };
}
