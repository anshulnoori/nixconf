_: {
  flake.modules.homeManager.base.programs.fzf = {
    enable = true;
    historyWidget.command = "";
  };

  flake.modules.homeManager.desktop.stylix.targets.fzf.enable = true;
}
