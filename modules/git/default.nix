{ ... }: {
  programs = {
    git = {
      enable = true;
      userName = "Shuo Zheng";
      userEmail = "github@shuo.dev";

      ignores = [
        ".DS_Store"
        ".envrc"
      ];

      aliases = {
        root = "rev-parse --show-toplevel";
      };

      extraConfig = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
        # Following are recommended by delta
        # https://github.com/dandavison/delta?tab=readme-ov-file#get-started
        delta.navigate = true;
        merge.conflictStyle = "diff3";
        diff.colorMoved = "default";
      };

      delta = {
        enable = true;
        options = {
          # side-by-side = true;
        };
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
