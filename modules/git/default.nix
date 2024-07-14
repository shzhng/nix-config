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
}