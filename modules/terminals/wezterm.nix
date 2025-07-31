{ pkgs, ... }:
let
  fonts = import ../fonts.nix { inherit pkgs; };

  # Generate harfbuzz features list from font configuration
  harfbuzzFeatures = builtins.filter (s: s != "") (
    builtins.map (name: if fonts.fonts.primary.features.${name} then name else "") (
      builtins.attrNames fonts.fonts.primary.features
    )
  );

  weztermConfig = ''
    local wezterm = require 'wezterm'

    return {
      -- Hide the title bar
      -- window_decorations = "RESIZE",

      enable_scroll_bar = true,
      hide_tab_bar_if_only_one_tab = true,
      tab_bar_at_bottom = true,
      use_fancy_tab_bar = false,

      -- Font configuration from central config
      font = wezterm.font {
        family = '${fonts.fonts.primary.family}',
        harfbuzz_features = {
          ${builtins.concatStringsSep ",\n          " (builtins.map (f: "'${f}'") harfbuzzFeatures)}
        }
      },

      font_size = 13,
    }
  '';
in
{
  programs.wezterm = {
    enable = true;
    extraConfig = weztermConfig;
  };
}
