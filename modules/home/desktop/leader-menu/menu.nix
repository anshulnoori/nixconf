_: {
  flake.modules.homeManager.desktop = {config, ...}: let
    colors = config.lib.stylix.colors;
    workspaceEntries = dispatch: description:
      builtins.genList (
        index: let
          workspace = index + 1;
          key =
            if workspace == 10
            then "0"
            else toString workspace;
        in {
          inherit key;
          desc = "${description} workspace ${toString workspace}";
          cmd = "hyprctl dispatch ${dispatch} ${toString workspace}";
        }
      )
      10;
  in {
    programs.wlr-which-key = {
      enable = true;
      settings = {
        font = "JetBrainsMono Nerd Font 14";
        background = "#${colors.base00}f2";
        color = "#${colors.base05}";
        border = "#${colors.base0D}";
        separator = "  →  ";
        border_width = 2;
        corner_r = 0;
        padding = 20;
        rows_per_column = 6;
        column_padding = 25;
        anchor = "center";
        menu =
          [
            {
              key = "space";
              desc = "Open applications";
              cmd = "walker";
            }
            {
              key = "Alt+space";
              desc = "Open desktop menu";
              cmd = "nixconf-menu";
            }
            {
              key = "Return";
              desc = "Open terminal";
              cmd = "kitty";
            }
            {
              key = "w";
              desc = "Close window";
              cmd = "hyprctl dispatch killactive";
            }
            {
              key = "l";
              desc = "Lock";
              cmd = "hyprlock";
            }
            {
              key = "m";
              desc = "Exit desktop";
              cmd = "uwsm stop";
            }
            {
              key = "Left";
              desc = "Focus left";
              cmd = "hyprctl dispatch movefocus l";
            }
            {
              key = "Right";
              desc = "Focus right";
              cmd = "hyprctl dispatch movefocus r";
            }
            {
              key = "Up";
              desc = "Focus up";
              cmd = "hyprctl dispatch movefocus u";
            }
            {
              key = "Down";
              desc = "Focus down";
              cmd = "hyprctl dispatch movefocus d";
            }
            {
              key = "s";
              desc = "Send window to workspace";
              submenu = workspaceEntries "movetoworkspace" "Move to";
            }
          ]
          ++ workspaceEntries "workspace" "Open";
      };
    };
  };
}
