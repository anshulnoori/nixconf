{inputs, ...}: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    notionCalendar = inputs.monorepo.packages.${pkgs.stdenv.hostPlatform.system}.notion-calendar;
  in {
    home.packages = [notionCalendar];

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/calendar" = ["com.cron.electron.desktop"];
        "x-scheme-handler/cron" = ["com.cron.electron.desktop"];
      };
    };
  };
}
