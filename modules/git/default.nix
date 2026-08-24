_: {
  programs = {
    git = {
      enable = true;

      lfs.enable = true;

      ignores = [
        ".DS_Store"
        ".envrc"
        # agent-agnostic worktree convention: <repo>/.worktrees/<branch>
        ".worktrees/"
      ];

      # Use new settings format (replaces userName, userEmail, aliases, extraConfig)
      # user.email is machine-specific and set in hosts/<hostname>/home.nix.
      # Lumaril work signing is scoped to ~/git/lumaril via conditional include
      # below so the work key is never used for personal repos.
      settings = {
        user = {
          name = "Shuo Zheng";
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

      # Conditional include: only applies inside ~/git/lumaril/**. Signs commits
      # with the Lumaril SSH key held in 1Password; personal commits are unsigned
      # by default.
      includes = [
        {
          condition = "gitdir:~/git/lumaril/";
          contents = {
            user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEBG6S0nj4gCq5Nf2vIwBqOXVb8GQbldX8Z0dsLXWBj0";
            commit.gpgsign = true;
            gpg.format = "ssh";
            gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
          };
        }
      ];
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
