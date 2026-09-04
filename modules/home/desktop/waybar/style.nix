_: {
  flake.modules.homeManager.desktop = {config, ...}: let
    colors = config.lib.stylix.colors;
  in {
    stylix.targets.waybar.enable = false;
    programs.waybar.style = ''
      @define-color foreground #${colors.base05};
      @define-color background #${colors.base00};
      @define-color accent #${colors.base0D};
      @define-color warning #${colors.base0A};

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
      #custom-menu,
      #custom-notion-calendar {
        min-width: 12px;
        margin: 0 7.5px;
      }

      #custom-notion-calendar.active { color: @accent; }
      #tray { margin-right: 16px; }
      #bluetooth { margin-right: 17px; }
      #network { margin-right: 13px; }
      #custom-expand-icon { margin-right: 18px; }
      #custom-screenrecording.active {
        color: #${colors.base08};
        margin-right: 17px;
      }
      #custom-update.updates {
        color: @warning;
        margin-right: 17px;
      }
      #custom-storage-health.warning {
        color: #${colors.base08};
        margin-right: 17px;
      }

      tooltip {
        padding: 2px;
        border: 2px solid #${colors.base03};
      }
    '';
  };
}
