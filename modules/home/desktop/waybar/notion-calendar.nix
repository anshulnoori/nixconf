_: {
  flake.modules.homeManager.desktop = {
    programs.waybar.settings.mainBar."tray#notion-calendar" = {
      only-id-prefix = "Notion Calendar_status_icon_";
      text-file = "notion-calendar/waybar.json";
      menu-on-left-click = true;
    };
  };
}
