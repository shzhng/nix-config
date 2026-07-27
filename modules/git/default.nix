_: {
  programs = {
    git = {
      enable = true;

      ignores = [
        ".DS_Store"
        ".envrc"
      ];

      signing = {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEBG6S0nj4gCq5Nf2vIwBqOXVb8GQbldX8Z0dsLXWBj0";
        signByDefault = true;
      };

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
        # Following are recommended by delta
        # https://github.com/dandavison/delta?tab=readme-ov-file#get-started
        delta.navigate = true;
        merge.conflictStyle = "diff3";
        diff.colorMoved = "default";
        credential.helper = "gh auth git-credential";
        gpg.format = "ssh";
        "gpg \"ssh\"".program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };
    };

    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        # side-by-side = true;
      };
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
