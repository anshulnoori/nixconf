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
    mainBar = home.programs.waybar.settings.mainBar;
    notionCalendarWaybar = mainBar."custom/notion-calendar";
    notionCalendarIndex = lib.lists.findFirstIndex (module: module == "custom/notion-calendar") null mainBar.modules-right;
    trayExpanderIndex = lib.lists.findFirstIndex (module: module == "group/tray-expander") null mainBar.modules-right;
    waybar = inputs.waybar.packages.${system}.waybar;
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
          on-click = "${notionCalendar}/bin/notion-calendar-waybar --activate";
          on-click-right = "${notionCalendar}/bin/notion-calendar-waybar --menu";
          tooltip = true;
        }) "Notion Calendar's Waybar module is misconfigured";
      assert lib.assertMsg (trayExpanderIndex != null && notionCalendarIndex == trayExpanderIndex + 1) "Notion Calendar is not immediately after Waybar's tray expander";
      assert lib.assertMsg (lib.hasInfix "#custom-notion-calendar.active { color: @accent; }" home.programs.waybar.style) "Notion Calendar's active Waybar style is missing";
      assert lib.assertMsg (builtins.elem "tray" mainBar."group/tray-expander".modules) "Waybar's StatusNotifierItem tray is missing";
      assert lib.assertMsg (builtins.elem "Notion Calendar_status_icon_" mainBar.tray.ignore-list) "Notion Calendar's duplicate tray icon is not ignored";
      assert lib.assertMsg (home.programs.waybar.package == waybar) "Waybar does not use the pinned post-ignore-list package";
        pkgs.runCommand "nixconf-notion-calendar" {} ''
          test -x ${notionCalendar}/bin/notion-calendar-waybar
          test -r ${notionCalendar}/share/applications/com.cron.electron.desktop
          test -x ${waybar}/bin/waybar
          touch "$out"
        '';
    };
  };
}
