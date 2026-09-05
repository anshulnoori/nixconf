_: {
  flake.modules.homeManager.base.programs = {
    eza = {
      enable = true;
      icons = "auto";
      extraOptions = ["--group-directories-first"];
    };
    zsh.shellAliases = {
      la = "eza --all --long";
      ll = "eza --long";
      lsa = "eza --all";
      lst = "eza --tree";
    };
  };
}
