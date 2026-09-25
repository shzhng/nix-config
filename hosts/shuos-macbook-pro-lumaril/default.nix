# Lumaril work MacBook Pro
_: {
  homebrew = {
    casks = [
      "granola"
      "headlamp"
      "notion"
      "parallels"
    ];

    masApps = {
      # iOS/iPadOS simulator runtimes are downloaded separately:
      # `xcodebuild -downloadPlatform iOS`
      "Xcode" = 497799835;
    };
  };

  home-manager.users.shuo.imports = [ ./home.nix ];
}
