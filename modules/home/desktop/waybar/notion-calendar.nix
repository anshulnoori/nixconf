{inputs, ...}: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    notionCalendar = inputs.monorepo.packages.${pkgs.stdenv.hostPlatform.system}.notion-calendar;
  in {
    programs.waybar.settings.mainBar."custom/notion-calendar" = {
      exec = "${notionCalendar}/bin/notion-calendar-waybar --follow";
      return-type = "json";
      escape = true;
      on-click = "${notionCalendar}/bin/notion-calendar-waybar --activate";
      on-click-right = "${notionCalendar}/bin/notion-calendar-waybar --menu";
      tooltip = true;
    };
  };
}
