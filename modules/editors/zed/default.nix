{ ... }:

let
  settingsFile = ../../../config/zed/settings.json;
  settingsContent = builtins.fromJSON (builtins.readFile settingsFile);
in
{
  programs.zed-editor = {
    enable = true;

    # Use settings from the external JSON file
    userSettings = settingsContent;
  };

  # Create a symlink to the settings.json file in the expected location
  # This allows for editing the settings through Zed's UI and having those changes
  # reflected in your nix-managed settings
  # home.file.".config/zed/settings.json".source = settingsFile;
}
