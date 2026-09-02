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

        hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
        hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
        hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
        hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
        hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

        hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
        hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
        hl.animation({ leaf = "windows", enabled = true, speed = 3.79, bezier = "easeOutQuint" })
        hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
        hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
        hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
        hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
        hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
        hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
        hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
        hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
        hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
        hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
        hl.animation({ leaf = "workspaces", enabled = false })
        hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slidevert" })

        hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"))
        hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("walker"))
        hl.bind("SUPER + ALT + SPACE", hl.dsp.exec_cmd("wlr-which-key"))
        hl.bind("SUPER + W", hl.dsp.window.close())
        hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock"))
        hl.bind("SUPER + M", hl.dsp.exec_cmd("uwsm stop"))

        hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
        hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
        hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
        hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))

        for i = 1, 10 do
          local key = i % 10
          hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
          hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
        end

        hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
        hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

        hl.bind("PRINT", hl.dsp.exec_cmd("capture-screenshot"))

        hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"))
        hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"))
        hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"))
        hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"))
        hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"))
        hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"))
        hl.bind("XF86AudioNext", hl.dsp.exec_cmd("swayosd-client --playerctl next"))
        hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("swayosd-client --playerctl prev"))
        hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"))
        hl.bind("XF86AudioStop", hl.dsp.exec_cmd("swayosd-client --playerctl stop"))

        hl.window_rule({
          match = { class = ".*" },
          opacity = 0.97,
        })
        hl.window_rule({
          match = { class = "kitty" },
          opacity = 0.93,
        })
        hl.window_rule({
          match = { title = "^(Open|Save) (File|Folder)$" },
          float = true,
          center = 1,
        })
        hl.layer_rule({
          match = { namespace = "walker" },
          no_anim = true,
          animation = "none",
        })
      '';
    };
  };
}
