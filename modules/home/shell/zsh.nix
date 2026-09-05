_: {
  flake.modules.homeManager.base = {
    programs.zsh = {
      enable = true;
      autocd = true;
      defaultKeymap = "viins";
    };
  };
}
