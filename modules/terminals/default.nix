{ pkgs, ... }:
let
  fonts = import ../fonts.nix { inherit pkgs; };
in
{
  imports = [
    ./wezterm.nix
  ];

  programs = {

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
    ghostty = {
      enable = true;
      package = null; # installed through homebrew

      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;

      settings = {
        # Font settings from central configuration
        font-family = fonts.fonts.primary.family;
        font-feature = builtins.concatStringsSep ", " (
          builtins.filter (s: s != "") (
            builtins.map (name: if fonts.fonts.primary.features.${name} then "+${name}" else "") (
              builtins.attrNames fonts.fonts.primary.features
            )
          )
        );
        font-size = 14;

        keybind = [
          # Shift+Enter to insert newline - required for Claude Code multiline input
          "shift+enter=text:\\n"
        ];
      };
    };
  };
}
