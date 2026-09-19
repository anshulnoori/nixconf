_: {
  flake.modules.homeManager.desktop = _: {
    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
        targets = ["graphical-session.target"];
      };
      settings.mainBar = {
        layer = "top";
        position = "top";
        spacing = 0;
        height = 26;
        modules-left = [
          "custom/menu"
          "hyprland/workspaces"
        ];
        modules-center = ["clock"];
        modules-right = [
          "custom/screenrecording"
          "custom/update"
          "group/tray-expander"
          "tray#notion-calendar"
          "bluetooth"
          "network"
          "pulseaudio"
          "cpu"
        ];

        "custom/menu" = {
          format = "";
          on-click = "nixconf-menu";
          tooltip-format = "Control Menu\n\nTap Super, then Alt+Space";
        };
        "hyprland/workspaces" = {
          on-click = "activate";
          format = "{icon}";
          format-icons = {
            default = "";
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "0";
            active = "󱓻";
          };
          persistent-workspaces = {
            "1" = [];
            "2" = [];
            "3" = [];
            "4" = [];
            "5" = [];
          };
        };
        clock = {
          format = "{:%a %b %e %I:%M%p}";
          interval = 60;
          tooltip = false;
        };
        "group/tray-expander" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 600;
            children-class = "tray-group-item";
          };
          modules = [
            "custom/expand-icon"
            "tray"
          ];
        };
        "custom/expand-icon" = {
          format = "";
          tooltip = false;
          on-scroll-up = "";
          on-scroll-down = "";
          on-scroll-left = "";
          on-scroll-right = "";
        };
        tray = {
          icon-size = 12;
          spacing = 17;
          ignore-list = ["Notion Calendar_status_icon_"];
        };
      };
    };
  };
}
