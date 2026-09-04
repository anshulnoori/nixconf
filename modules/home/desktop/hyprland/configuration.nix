_: {
  flake.modules.homeManager.desktop = {config, ...}: let
    colors = config.lib.stylix.colors;
  in {
    stylix.targets.hyprland.enable = false;

    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
      configType = "lua";
      systemd.enable = false;
      extraConfig = ''
        hl.monitor({
          output = "",
          mode = "preferred",
          position = "auto",
          scale = "auto",
        })

        hl.config({
          general = {
            gaps_in = 5,
            gaps_out = 10,
            border_size = 2,
            ["col.active_border"] = "rgb(${colors.base0D})",
            ["col.inactive_border"] = "rgba(${colors.base03}aa)",
            layout = "dwindle",
          },
          decoration = {
            rounding = 0,
            rounding_power = 2,
            active_opacity = 1.0,
            inactive_opacity = 1.0,
            fullscreen_opacity = 1.0,
            shadow = {
              enabled = true,
              range = 4,
              render_power = 3,
              color = "rgba(${colors.base00}55)",
            },
            blur = {
              enabled = true,
              size = 3,
              passes = 1,
              vibrancy = 0.1696,
            },
          },
          input = {
            kb_layout = "us",
            follow_mouse = 1,
          },
          group = {
            ["col.border_active"] = "rgb(${colors.base0D})",
            ["col.border_inactive"] = "rgba(${colors.base03}aa)",
            ["col.border_locked_active"] = "rgb(${colors.base0A})",
            ["col.border_locked_inactive"] = "rgba(${colors.base03}aa)",
            groupbar = {
              enabled = true,
              font_family = "JetBrainsMono Nerd Font",
              font_size = 11,
              height = 14,
              gradients = false,
              ["col.active"] = "rgb(${colors.base0D})",
              ["col.inactive"] = "rgb(${colors.base01})",
              ["col.locked_active"] = "rgb(${colors.base0A})",
              ["col.locked_inactive"] = "rgb(${colors.base01})",
            },
          },
          misc = {
            disable_hyprland_logo = true,
            force_default_wallpaper = 0,
            background_color = 0xff${colors.base00},
            disable_splash_rendering = true,
          },
        })
      '';
    };
  };
}
