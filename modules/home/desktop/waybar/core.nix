_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    clock = pkgs.writeShellScript "waybar-clock" ''
      while true; do
        LC_TIME=C ${pkgs.coreutils}/bin/date '+%a %b %-d %-I:%M%P'
        seconds="$(${pkgs.coreutils}/bin/date '+%S')"
        ${pkgs.coreutils}/bin/sleep "$((60 - 10#$seconds))"
      done
    '';
  in {
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
        modules-center = ["custom/clock"];
        modules-right = [
          "custom/screenrecording"
          "custom/update"
          "custom/storage-health"
          "group/tray-expander"
          "custom/notion-calendar"
          "bluetooth"
          "network"
          "pulseaudio"
          "cpu"
        ];

        "custom/menu" = {
          format = "";
          on-click = "nixconf-menu";
          tooltip-format = "Control Menu\n\nSuper + Alt + Space";
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
        "custom/clock" = {
          exec = "${clock}";
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
