_: {
  flake.modules.homeManager.base = {
    programs = {
      bat.enable = true;
      zsh.shellAliases.cat = "bat";
    };
  };

  flake.modules.homeManager.desktop.stylix.targets.bat.enable = true;
}
