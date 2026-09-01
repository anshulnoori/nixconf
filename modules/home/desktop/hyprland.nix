_: {
  flake.modules.homeManager.desktop = {config, ...}: let
    colors = config.lib.stylix.colors;
  in {
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
            gaps_in = 4,
            gaps_out = 8,
            border_size = 2,
            layout = "dwindle",
          },
          decoration = {
            rounding = 0,
            shadow = { enabled = false },
            blur = { enabled = false },
          },
          input = {
            kb_layout = "us",
            follow_mouse = 1,
          },
          misc = {
            disable_hyprland_logo = true,
            force_default_wallpaper = 0,
            background_color = 0xff${colors.base00},
          },
        })

        hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"))
        hl.bind("SUPER + D", hl.dsp.exec_cmd("fuzzel"))
        hl.bind("SUPER + Q", hl.dsp.window.close())
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
      '';
    };
  };
}
