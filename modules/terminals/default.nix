{ pkgs, ... }: {
  programs = {
    # Main driver right now
    wezterm = {
      enable = true;
      extraConfig = builtins.readFile ../wezterm/wezterm.lua;
    };

    # Testing out other ones
    alacritty = {
      enable = true;
      settings = pkgs.lib.importTOML ../alacritty/alacritty.toml;
    };

    kitty = {
      enable = true;
      shellIntegration = {
        enableFishIntegration = true;
        enableZshIntegration = true;
      };
      extraConfig = builtins.readFile ../kitty/kitty.conf;
    };
  };
}