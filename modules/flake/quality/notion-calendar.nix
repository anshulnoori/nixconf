{inputs, ...}: {
  perSystem = {
    lib,
    pkgs,
    system,
    ...
  }: let
    home = inputs.self.nixosConfigurations.t1.config.home-manager.users.mvs;
    mimeDefaults = home.xdg.mimeApps.defaultApplications;
    notionCalendar = inputs.monorepo.packages.${system}.notion-calendar;
    notionCalendarWaybar = home.programs.waybar.settings.mainBar."custom/notion-calendar";
  in {
    checks = lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      notion-calendar = assert lib.assertMsg (builtins.elem notionCalendar home.home.packages) "Notion Calendar is not installed";
      assert lib.assertMsg (builtins.any (package: lib.getName package == "todoist-electron") home.home.packages) "Todoist is not installed";
      assert lib.assertMsg (mimeDefaults."text/calendar" == ["com.cron.electron.desktop"]) "Notion Calendar is not the calendar default";
      assert lib.assertMsg (mimeDefaults."x-scheme-handler/cron" == ["com.cron.electron.desktop"]) "Notion Calendar is not the cron handler";
      assert lib.assertMsg (notionCalendarWaybar
        == {
          exec = "${notionCalendar}/bin/notion-calendar-waybar --follow";
          return-type = "json";
          escape = true;
          on-click = "${notionCalendar}/bin/notion-calendar-waybar --open";
          on-click-right = "${notionCalendar}/bin/notion-calendar-waybar --menu";
          tooltip = true;
        }) "Notion Calendar's Waybar module is misconfigured";
      assert lib.assertMsg (builtins.elem "custom/notion-calendar" home.programs.waybar.settings.mainBar.modules-right) "Notion Calendar is not visible in Waybar";
      assert lib.assertMsg (lib.hasInfix "#custom-notion-calendar.active { color: @accent; }" home.programs.waybar.style) "Notion Calendar's active Waybar style is missing";
      assert lib.assertMsg (builtins.elem "tray" home.programs.waybar.settings.mainBar."group/tray-expander".modules) "Waybar's StatusNotifierItem tray is missing";
        pkgs.runCommand "nixconf-notion-calendar" {} ''
          test -x ${notionCalendar}/bin/notion-calendar-waybar
          test -r ${notionCalendar}/share/applications/com.cron.electron.desktop
          touch "$out"
        '';
    };
  };
}
