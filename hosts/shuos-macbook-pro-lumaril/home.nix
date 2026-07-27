# Home configuration specific to the Lumaril work MacBook Pro
{ ... }:
{
  programs.git = {
    settings.user.email = "shuo@lumaril.com";

    # Sign commits with the Lumaril-specific SSH key held in 1Password
    signing = {
      format = "ssh";
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEBG6S0nj4gCq5Nf2vIwBqOXVb8GQbldX8Z0dsLXWBj0";
      signByDefault = true;
      signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    };
  };
}
