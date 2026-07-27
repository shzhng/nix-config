# Lumaril work MacBook Pro
{ ... }:
{
  homebrew.casks = [
    "headlamp"
    "notion"
    "parallels"
    "zoom"
  ];

  home-manager.users.shuo.imports = [ ./home.nix ];
}
