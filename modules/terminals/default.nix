{ pkgs, ... }: {
  programs = {
    # Main driver right now
    wezterm = {
      enable = true;
      extraConfig = builtins.readFile ../../config/wezterm/wezterm.lua;
    };

    # Testing out other ones
    # alacritty = {
    #   enable = true;
    #   settings = pkgs.lib.importTOML ../../config/alacritty/alacritty.toml;
    # };

    # kitty = {
    #   enable = true;
    #   shellIntegration = {
    #     enableFishIntegration = true;
    #     enableZshIntegration = true;
    #   };
    #   extraConfig = builtins.readFile ../../config/kitty/kitty.conf;
    #   themeFile = "${pkgs.catppuccin-kitty}/share/kitty-themes/Catppuccin-Mocha.conf";
    # };

    # Configure ghostty
    # ghostty is actually broken nixpkg on darwin. Installed through homebrew.
    # https://github.com/NixOS/nixpkgs/pull/369788 and https://github.com/NixOS/nixpkgs/issues/388984
    # ghostty = {
    #   enable = true;
    #   settings = {
    #     # Add your ghostty settings here
    #     # For example:
    #     # font-family = "JetBrains Mono";
    #     # font-size = 12;
    #   };
    # };
  };
}
