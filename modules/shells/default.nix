{ pkgs, ... }:
{
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
      # This is a function that sets up a poetry environment using `layout poetry` in `.envrc`
      # See https://github.com/direnv/direnv/wiki/Python#poetry
      stdlib = ''
        layout_poetry() {
            PYPROJECT_TOML="$\{PYPROJECT_TOML:-pyproject.toml\}"
            if [[ ! -f "$PYPROJECT_TOML" ]]; then
                log_status "No pyproject.toml found. Executing \`poetry init\` to create a \`$PYPROJECT_TOML\` first."
                poetry init
            fi

            if [[ -d ".venv" ]]; then
                VIRTUAL_ENV="$(pwd)/.venv"
            else
                VIRTUAL_ENV=$(poetry env info --path 2>/dev/null ; true)
            fi

            if [[ -z $VIRTUAL_ENV || ! -d $VIRTUAL_ENV ]]; then
                log_status "No virtual environment exists. Executing \`poetry install\` to create one."
                poetry install
                VIRTUAL_ENV=$(poetry env info --path)
            fi

            PATH_add "$VIRTUAL_ENV/bin"
            export POETRY_ACTIVE=1  # or VENV_ACTIVE=1
            export VIRTUAL_ENV
        }
      '';
    };

    # Use starship for a universal prompt that's consistent across shells
    starship = {
      enable = true;
      settings = pkgs.lib.importTOML ../../config/starship/starship.toml;
    };

    tmux = {
      enable = true;
      terminal = "screen-256color";
      mouse = true;
      keyMode = "vi";
    };
  };
}
