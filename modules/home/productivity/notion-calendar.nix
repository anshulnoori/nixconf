{inputs, ...}: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    notionCalendar = pkgs.callPackage ../../../packages/notion-calendar.nix {
      notionCalendar = inputs.monorepo.packages.${pkgs.stdenv.hostPlatform.system}.notion-calendar;
    };
  in {
    home.packages = [notionCalendar];

    # Keep separate from the startup file managed by the app itself.
    xdg.configFile."autostart/nix-notion-calendar.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Notion Calendar
      Exec=${notionCalendar}/bin/notion-calendar --from-login
      Terminal=false
    '';

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/calendar" = ["com.cron.electron.desktop"];
        "x-scheme-handler/cron" = ["com.cron.electron.desktop"];
      };
    };
  };
}
