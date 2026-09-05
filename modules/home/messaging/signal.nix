_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home.packages = [pkgs.signal-desktop];

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/sgnl" = ["signal.desktop"];
        "x-scheme-handler/signalcaptcha" = ["signal.desktop"];
      };
    };
  };
}
