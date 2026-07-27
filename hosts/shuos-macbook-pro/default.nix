# Personal MacBook Pro
{ ... }:
{
  homebrew = {
    casks = [
      "astro-command-center"
      "firefox"
      "ibkr"
      "ledger-wallet"
      "logitech-g-hub"
      "microsoft-auto-update"
      "microsoft-office"
      "microsoft-teams"
      "moonlight"
      "mullvad-vpn"
      "openbb-terminal"
      "plex"
      "steam"
      "tailscale-app"
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
