_: {
  programs = {
    git = {
      enable = true;

      ignores = [
        ".DS_Store"
        ".envrc"
      ];

      # Sign commits with the 1Password SSH key on all machines
      signing = {
        format = "ssh";
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEBG6S0nj4gCq5Nf2vIwBqOXVb8GQbldX8Z0dsLXWBj0";
        signByDefault = true;
        signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };

      # Use new settings format (replaces userName, userEmail, aliases, extraConfig)
      settings = {
        user = {
          name = "Shuo Zheng";
          email = "shuo@lumaril.com";
        };
        alias = {
          root = "rev-parse --show-toplevel";
        };
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
        merge.conflictStyle = "diff3";
        diff.colorMoved = "default";
        credential.helper = "gh auth git-credential";
      };
    };

    # Delta installed for manual use, but not as default git pager (for agent compatibility)
    # Use manually with: git diff | delta
    delta = {
      enable = true;
      enableGitIntegration = false;
    };

    lazygit = {
      enable = true;
      settings = {
        git = {
          paging = {
            # https://github.com/jesseduffield/lazygit/blob/master/docs/Custom_Pagers.md
            colorArg = "always";
            useConfig = false;
            pager = "delta --dark --paging=never";
          };
        };
      };
    };
  };

  home.shellAliases = {
    "g" = "git";
    "ga" = "git add";
    "gc" = "git commit";
    "gcam" = "git commit -a -m";
    "gd" = "git diff";
    "gds" = "git diff --staged";
    "gf" = "git fetch";
    "gm" = "git merge";
    "gp" = "git push";
    "grt" = "cd (git root)";
    "gst" = "git status";
  };
}
