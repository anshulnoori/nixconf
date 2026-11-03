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
        modules-left = ["group/left-cluster"];
        # A plain group gets the `expanded` class while the pointer is over it, which style.nix
        # uses to fade the otherwise hidden logo and workspaces in.
        "group/left-cluster" = {
          orientation = "inherit";
          modules = [
            "custom/menu"
            "hyprland/workspaces"
          ];
        };
        modules-center = ["clock"];
        modules-right = [
          "custom/screenrecording"
          "group/tray-expander"
          "tray#notion-calendar"
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
            # Matches Hyprland's border animation (speed 5.39) and the fades in style.nix.
            transition-duration = 539;
            children-class = "tray-group-item";
          };
          # Static status icons stay in the drawer to limit OLED burn-in; it opens when the pointer nears it.
          modules = [
            "custom/expand-icon"
            "tray"
            "bluetooth"
            "network"
            "pulseaudio"
            "cpu"
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
