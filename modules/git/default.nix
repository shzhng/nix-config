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
      };
      difftastic.enable = true;
    };
    lazygit.enable = true;
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
