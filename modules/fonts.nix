{ pkgs, ... }:

{
  # Central font configuration
  fonts = {
    # Primary coding font
    primary = {
      family = "MonaspiceNe Nerd Font Mono";
      package = pkgs.nerd-fonts.monaspace;
      features = {
        # Stylistic sets for programming ligatures
        ss01 = true; # ==, !=, ===, !==
        ss02 = true; # >=, <=
        ss03 = true; # ->, =>, |>
        ss04 = true; # &&, ||
        ss05 = true; # @, #
        ss06 = true; # \\, //, /*
        ss07 = true; # =~, !~
        ss08 = true; # ++, --, **
        # Standard ligatures
        liga = true;
        dlig = true; # Discretionary ligatures
        calt = true; # Contextual alternates
      };
    };

    # UI font (for non-code interfaces)
    ui = {
      family = "Hubot Sans";
      package = pkgs.hubot-sans;
    };

    # All font packages to install
    packages = with pkgs; [
      fira-code
      hubot-sans
      jetbrains-mono
      monaspace
      nerd-fonts.hack
      nerd-fonts.monaspace
      source-code-pro
    ];
  };
}
