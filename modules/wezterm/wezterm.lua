local wezterm = require 'wezterm'

return {
  -- Hide the title bar
  -- window_decorations = "RESIZE",

  enable_scroll_bar = true,
  hide_tab_bar_if_only_one_tab = true,
  tab_bar_at_bottom = true,
  use_fancy_tab_bar = false,

  color_scheme = "Catppuccin Mocha",

  -- Monaspace:  https://monaspace.githubnext.com/
  -- Taken from https://github.com/HaleTom/dotfiles/blob/a2049913a35676eb4c449ebaff09f65abe055f62/wezterm/.config/wezterm/wezterm.lua#L93
  font = wezterm.font {
    -- Normal text
    family = 'Monaspace Neon',
    -- family = 'Monaspace Argon',
    -- family = 'Monaspace Xenon',
    -- family = 'Monaspace Radon',
    -- family = 'Monaspace Krypton',
    harfbuzz_features = {
      'calt',
      'liga',
      'dlig',
      'ss01',
      'ss02',
      'ss03',
      'ss04',
      'ss05',
      'ss06',
      'ss07',
      'ss08'
    }
  },

  font_size = 13,

  font_rules = {
    {
      -- Italic
      intensity = 'Normal',
      italic = true,
      font = wezterm.font {
        family = 'Monaspace Radon',
      }
    },
    {
      -- Bold
      intensity = 'Bold',
      italic = false,
      font = wezterm.font {
        family = 'Monaspace Neon',
        weight = 'Bold'
      }
    },
    {
      -- Bold Italic
      intensity = 'Bold',
      italic = true,
      font = wezterm.font {
        family = 'Monaspace Radon',
        weight = 'Bold'
      }
    }
  }
}
