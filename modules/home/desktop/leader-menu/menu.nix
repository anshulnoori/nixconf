_: {
  flake.modules.homeManager.desktop = {config, ...}: let
    colors = config.lib.stylix.colors;
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
        menu = [
          {
            key = "c";
            desc = "Clipboard history";
            cmd = "walker -m clipboard";
          }
          {
            key = "n";
            desc = "Notifications";
            submenu = [
              {
                key = "d";
                desc = "Dismiss latest";
                cmd = "makoctl dismiss";
              }
              {
                key = "a";
                desc = "Dismiss all";
                cmd = "makoctl dismiss --all";
              }
              {
                key = "m";
                desc = "Toggle do not disturb";
                cmd = "sh -c 'makoctl mode | grep -q do-not-disturb && makoctl mode -r do-not-disturb || makoctl mode -a do-not-disturb'";
              }
            ];
          }
          {
            key = "p";
            desc = "Install Nixpkgs package";
            cmd = "present-terminal 'Nixpkgs package search' nixpkgs-package-search";
          }
          {
            key = "t";
            desc = "System tools";
            submenu = [
              {
                key = "a";
                desc = "Audio";
                cmd = "kitty --class TUI.float wiremix";
              }
              {
                key = "b";
                desc = "Bluetooth";
                cmd = "kitty --class TUI.float bluetui";
              }
              {
                key = "n";
                desc = "Network";
                cmd = "kitty --class TUI.float impala";
              }
              {
                key = "s";
                desc = "System monitor";
                cmd = "kitty --class TUI.float btop";
              }
            ];
          }
          {
            key = "u";
            desc = "UI";
            submenu = [
              {
                key = "b";
                desc = "Toggle bar";
                cmd = "sh -c 'systemctl --user is-active --quiet waybar.service && systemctl --user stop waybar.service || systemctl --user start waybar.service'";
              }
              {
                key = "i";
                desc = "Toggle idle management";
                cmd = "sh -c 'systemctl --user is-active --quiet hypridle.service && systemctl --user stop hypridle.service || systemctl --user start hypridle.service'";
              }
            ];
          }
          {
            key = "s";
            desc = "Suspend";
            cmd = "systemctl suspend";
          }
        ];
      };
    };
  };
}
