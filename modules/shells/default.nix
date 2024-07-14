{ pkgs, ... }: {
  programs = {
    # Add in all shells I could possibly use to make sure all programs set up
    # autcompletion prompt injection, etc properly
    zsh = {
      enable = true;
      syntaxHighlighting.enable = true;
    };
    fish.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Use starship for a universal prompt that's consistent across shells
    starship = {
      enable = true;
      settings = pkgs.lib.importTOML ../starship/starship.toml;
    };

    tmux = {
      enable = true;
      terminal = "screen-256color";
      mouse = true;
      keyMode = "vi";
    };
  };
}