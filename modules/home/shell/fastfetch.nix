_: {
  flake.modules.homeManager.desktop = {config, ...}: let
    colors = config.lib.stylix.colors;
    accent = "#${colors.base0D}";
  in {
    programs.fastfetch = {
      enable = true;
      settings = {
        logo = {
          source = "NixOS";
          padding.right = 2;
        };
        display = {
          separator = "  ";
          color = {
            keys = accent;
            separator = "#${colors.base04}";
          };
        };
        modules = [
          "break"
          {
            type = "title";
            color = {
              user = "#${colors.base0A}";
              at = "#${colors.base04}";
              host = "#${colors.base0B}";
            };
          }
          "separator"
          {
            type = "os";
            key = " OS";
          }
          {
            type = "host";
            key = "󰌢 Host";
          }
          {
            type = "kernel";
            key = " Kernel";
          }
          {
            type = "uptime";
            key = "󰅐 Uptime";
          }
          "break"
          {
            type = "cpu";
            key = " CPU";
          }
          {
            type = "gpu";
            key = "󰢮 GPU";
          }
          {
            type = "memory";
            key = " Memory";
          }
          {
            type = "disk";
            key = "󰋊 Disk";
          }
          "break"
          {
            type = "wm";
            key = " WM";
          }
          {
            type = "terminal";
            key = " Terminal";
          }
          {
            type = "shell";
            key = " Shell";
          }
          {
            type = "packages";
            key = "󰏖 Packages";
          }
          "break"
          {
            type = "colors";
            symbol = "circle";
          }
        ];
      };
    };
  };
}
