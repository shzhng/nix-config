# Lumaril work MacBook Pro
{ ... }:
{
  homebrew.casks = [
    "headlamp"
    "notion"
    "parallels"
  ];

  home-manager.users.shuo.imports = [ ./home.nix ];
}
