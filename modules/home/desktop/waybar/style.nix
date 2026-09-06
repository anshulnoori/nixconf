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
      #custom-menu {
        min-width: 12px;
        margin: 0 7.5px;
      }

      #tray.notion-calendar {
        min-width: 12px;
        margin: 0 17px 0 0;
      }

      #tray.notion-calendar label.active {
        color: @accent;
        border-left: 3px solid @accent;
        border-radius: 2px;
        padding-left: 6px;
        margin: 4px 0;
      }
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

      menu {
        padding: 4px;
        border: 1px solid #${colors.base03};
        border-radius: 6px;
      }
      menuitem { padding: 4px 10px; }
      menuitem label { color: @foreground; background-color: transparent; }
      menuitem:hover { background-color: #${colors.base02}; }
      menuitem:disabled label { color: #${colors.base04}; }
      menuitem arrow { min-width: 8px; min-height: 8px; }
      menuitem check, menuitem radio {
        min-width: 12px;
        min-height: 12px;
        border: 1px solid @foreground;
      }
      menuitem check:checked, menuitem radio:checked { background-color: @accent; }
      menu separator { min-height: 1px; background-color: #${colors.base03}; }

      tooltip {
        padding: 2px;
        border: 2px solid #${colors.base03};
      }
    '';
  };
}
