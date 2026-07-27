# Home configuration specific to the personal MacBook Pro
{ pkgs, ... }:
{
  programs.git.settings.user.email = "github@shuo.dev";

  home.packages = with pkgs; [
    code-cursor
    devenv
    discord
    # spotify # Temporarily disabled due to hash mismatch
    vscode
    zoom-us
  ];
}
