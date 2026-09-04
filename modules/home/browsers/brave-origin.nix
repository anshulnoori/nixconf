_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home.packages = [pkgs.brave-origin];
    home.sessionVariables.BROWSER = "brave-origin";

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = ["brave-origin.desktop"];
        "x-scheme-handler/http" = ["brave-origin.desktop"];
        "x-scheme-handler/https" = ["brave-origin.desktop"];
      };
    };
  };
}
