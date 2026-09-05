_: {
  flake.modules.homeManager.base = {
    programs = {
      ripgrep.enable = true;
      zsh.shellAliases.grep = "rg";
    };
  };
}
