_: {
  flake.modules.homeManager.desktop = {
    config,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
    floatingTerminal = command: "kitty --class TUI.float ${command}";
    screenrecordingIndicator = pkgs.writeShellApplication {
      name = "nixconf-screenrecording-indicator";
      text = ''
        if capture-screenrecord active; then
          printf '{"text":"󰻂","tooltip":"Stop screen recording","class":"active"}\n'
        else
          printf '{"text":""}\n'
        fi
      '';
    };
  in {
    stylix.targets.waybar.enable = false;

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
          "group/tray-expander"
          "bluetooth"
          "network"
          "pulseaudio"
          "cpu"
        ];

        "custom/menu" = {
          format = "";
          on-click = "nixconf-menu";
          tooltip = false;
        };
        "custom/screenrecording" = {
          exec = "${screenrecordingIndicator}/bin/nixconf-screenrecording-indicator";
          return-type = "json";
          interval = 1;
          on-click = "capture-screenrecord stop";
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
          format = "{:%a %d %b  %I:%M %p}";
          format-alt = "{:%A %d %B W%V %Y}";
          tooltip = false;
        };
        cpu = {
          interval = 5;
          format = "󰍛";
          on-click = floatingTerminal "btop";
        };
        network = {
          format = "{icon}";
          format-wifi = "{icon}";
          format-ethernet = "󰀂";
          format-disconnected = "󰤮";
          format-icons = [
            "󰤯"
            "󰤟"
            "󰤢"
            "󰤥"
            "󰤨"
          ];
          tooltip-format-wifi = "{essid} ({frequency} GHz)";
          tooltip-format-ethernet = "Connected";
          tooltip-format-disconnected = "Disconnected";
          interval = 3;
          on-click = floatingTerminal "impala";
        };
        bluetooth = {
          format = "";
          format-off = "󰂲";
          format-disabled = "󰂲";
          format-connected = "󰂱";
          format-no-controller = "󰂲";
          tooltip-format = "Devices connected: {num_connections}";
          on-click = floatingTerminal "bluetui";
        };
        pulseaudio = {
          format = "{icon}";
          format-muted = "";
          format-icons = {
            headphone = "";
            headset = "";
            default = [
              ""
              ""
              ""
            ];
          };
          tooltip-format = "Playing at {volume}%";
          scroll-step = 5;
          on-click = floatingTerminal "wiremix";
          on-click-right = "pamixer -t";
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
        };
        tray = {
          icon-size = 12;
          spacing = 17;
        };
      };
      style = ''
        @define-color foreground #${colors.base05};
        @define-color background #${colors.base00};
        @define-color accent #${colors.base0D};

        * {
          background-color: @background;
          color: @foreground;
          border: none;
          border-radius: 0;
          min-height: 0;
          font-family: "JetBrainsMono Nerd Font";
          font-size: 12px;
        }

        .modules-left { margin-left: 8px; }
        .modules-right { margin-right: 8px; }

        #workspaces button {
          all: initial;
          color: @foreground;
          padding: 0 6px;
          margin: 0 1.5px;
          min-width: 9px;
        }

        #workspaces button.empty { opacity: 0.5; }
        #workspaces button.active { color: @accent; }

        #cpu,
        #pulseaudio,
        #custom-menu {
          min-width: 12px;
          margin: 0 7.5px;
        }

        #tray { margin-right: 16px; }
        #bluetooth { margin-right: 17px; }
        #network { margin-right: 13px; }
        #custom-expand-icon { margin-right: 18px; }
        #custom-screenrecording.active {
          color: #${colors.base08};
          margin-right: 17px;
        }

        tooltip {
          padding: 2px;
          border: 2px solid #${colors.base03};
        }
      '';
    };

    home.packages = [pkgs.pamixer];
  };
}
