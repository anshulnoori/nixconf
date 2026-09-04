_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home.packages = [pkgs.todoist-electron];

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/com.todoist" = ["todoist.desktop"];
        "x-scheme-handler/todoist" = ["todoist.desktop"];
      };
    };
  };
}
