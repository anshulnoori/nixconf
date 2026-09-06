_: {
  flake.modules.homeManager.desktop = {
    programs.waybar.settings.mainBar."tray#notion-calendar" = {
      only-id-prefix = "Notion Calendar_status_icon_";
      # Relative to XDG_RUNTIME_DIR; Notion atomically publishes text/tooltip.
      # The native SNI owns menu actions and app lifetime, not a shell proxy.
      text-file = "notion-calendar/waybar.json";
      menu-on-left-click = true;
    };
  };
}
