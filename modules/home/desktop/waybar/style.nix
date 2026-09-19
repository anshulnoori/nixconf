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

      #tray { margin-right: 16px; }
      #bluetooth { margin-right: 17px; }
      #network { margin-right: 13px; }
      #custom-expand-icon { margin-right: 18px; }
      #custom-screenrecording.active {
        color: #${colors.base08};
        margin-right: 17px;
      }
      #custom-update.updates,
      #custom-update.unavailable,
      #custom-update.failed {
        margin-right: 17px;
      }
      #custom-update.updates:not(.running),
      #custom-update.updates:not(.running) label {
        color: @warning;
      }
      #custom-update.updates {
        min-width: 18px;
      }
      #custom-update.running {
        background-image: linear-gradient(@foreground, @foreground),
                          linear-gradient(alpha(@foreground, 0.55), alpha(@foreground, 0.55));
        background-position: 1.5px calc(80% + 1px);
        background-repeat: no-repeat;
        background-size: 0px 2px, 14px 2px;
      }
      #custom-update.progress-20 { background-size: 2.8px 2px, 14px 2px; }
      #custom-update.progress-40 { background-size: 5.6px 2px, 14px 2px; }
      #custom-update.progress-60 { background-size: 8.4px 2px, 14px 2px; }
      #custom-update.progress-80 { background-size: 11.2px 2px, 14px 2px; }
      #custom-update.updates label {
        min-width: 16px;
        padding-right: 2px;
        background-color: transparent;
      }
      #custom-update.failed,
      #custom-update.failed label {
        color: #${colors.base08};
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
