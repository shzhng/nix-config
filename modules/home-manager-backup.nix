{ pkgs, ... }:
{
  # Import alongside Home Manager's nix-darwin or NixOS integration module.
  # The policy is global to every Home Manager user managed by that system.
  home-manager.backupCommand = pkgs.writeShellScript "home-manager-backup" ''
    set -eu

    target="$1"
    timestamp="$(${pkgs.coreutils}/bin/date -u +%Y%m%dT%H%M%S.%N)"
    ${pkgs.coreutils}/bin/mv -- "$target" "$target.backup-$timestamp"
  '';
}
