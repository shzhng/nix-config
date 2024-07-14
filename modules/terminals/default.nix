{ pkgs, ... }: {
  programs = {
    # Main driver right now
    wezterm = {
      enable = true;
      extraConfig = builtins.readFile ../../config/wezterm/wezterm.lua;
    };

    # Testing out other ones
    alacritty = {
      enable = true;
      settings = pkgs.lib.importTOML ../../config/alacritty/alacritty.toml;
    };

    kitty = {
      enable = true;
      shellIntegration = {
        enableFishIntegration = true;
        enableZshIntegration = true;
      };
      extraConfig = builtins.readFile ../../config/kitty/kitty.conf;
    };
  };
}