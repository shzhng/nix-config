{ ... }:
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
      # Adopt the new home-manager defaults: no Python/Ruby provider
      # runtimes (nothing in our nvim config uses remote plugins).
      withPython3 = false;
      withRuby = false;
    };
  };
}
