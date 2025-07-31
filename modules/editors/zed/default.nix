{ pkgs, lib, ... }:

let
  fonts = import ../../fonts.nix { inherit pkgs; };

  # Read existing settings file
  settingsFile = ../../../config/zed/settings.json;
  settingsContent = builtins.fromJSON (builtins.readFile settingsFile);

  # Generate font features for Zed from central configuration
  # Filter out standard ligature features that Zed doesn't support in buffer_font_features
  fontFeatures = lib.filterAttrs (
    name: value:
    value
    && !builtins.elem name [
      "liga"
      "dlig"
      "calt"
    ]
  ) fonts.fonts.primary.features;

  # Merge font settings with existing settings
  mergedSettings = settingsContent // {
    "buffer_font_family" = fonts.fonts.primary.family;
    "buffer_font_features" = fontFeatures;
    "ui_font_family" = fonts.fonts.ui.family;
  };
in
{
  programs.zed-editor = {
    enable = true;

    # Use merged settings
    userSettings = mergedSettings;
  };

  # Create a symlink to the settings.json file in the expected location
  # This allows for editing the settings through Zed's UI and having those changes
  # reflected in your nix-managed settings
  # home.file.".config/zed/settings.json".source = settingsFile;
}
