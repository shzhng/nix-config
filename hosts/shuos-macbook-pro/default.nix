# Personal MacBook Pro
_: {
  homebrew = {
    casks = [
      "astro-command-center"
      "firefox"
      "ibkr"
      "ledger-wallet"
      "logitech-g-hub"
      "microsoft-auto-update"
      "microsoft-teams"
      "moonlight"
      "mullvad-vpn"
      "openbb-terminal"
      "plex"
      "steam"
      "thinkorswim"
      "trader-workstation"
      "yubico-authenticator"
    ];

    masApps = {
      "WireGuard" = 1451685025;
    };
  };

  home-manager.users.shuo.imports = [ ./home.nix ];
}
