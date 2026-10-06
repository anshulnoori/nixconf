_: {
  flake.modules.homeManager.desktop = {
    lib,
    pkgs,
    ...
  }: {
    home.packages = [pkgs.readest];

    xdg.desktopEntries.readest = {
      name = "Readest";
      exec = "${lib.getExe pkgs.readest} %f";
      icon = "readest";
      terminal = false;
      categories = ["Office"];
      mimeType = ["application/pdf" "application/epub+zip"];
      settings.StartupWMClass = "readest";
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = ["readest.desktop"];
        "application/epub+zip" = ["readest.desktop"];
      };
    };
  };
}
