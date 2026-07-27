# Lumaril work MacBook Pro
_: {
  homebrew.casks = [
    "headlamp"
    "notion"
    "parallels"
  ];

  home-manager.users.shuo.imports = [ ./home.nix ];
}
