_: {
  flake.modules.homeManager.desktop = {
    programs.obsidian.enable = true;
    stylix.targets.obsidian.enable = true;
    xdg.mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/obsidian" = ["obsidian.desktop"];
    };
  };
}
