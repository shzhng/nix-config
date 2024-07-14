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
      extraConfig = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
      };
      difftastic.enable = true;
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
    "gst" = "git status";
  };
}
