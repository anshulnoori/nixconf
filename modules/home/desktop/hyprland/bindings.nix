_: {
  flake.modules.homeManager.desktop.wayland.windowManager.hyprland.extraConfig = ''
    -- Explicit key states avoid Hyprland leaving a synthetic shortcut stuck.
    local function send_shortcut_once(mods, key)
      return function()
        hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down", window = "activewindow" }))

        hl.timer(function()
          hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up", window = "activewindow" }))
        end, { timeout = 50, type = "oneshot" })
      end
    end

    hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"))
    hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("walker"))
    hl.bind("SUPER + ALT + SPACE", hl.dsp.exec_cmd("nixconf-menu"))
    hl.bind("F13", hl.dsp.exec_cmd("wlr-which-key"))
    hl.bind("SUPER + W", hl.dsp.window.close())
    hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock"))
    hl.bind("SUPER + M", hl.dsp.exec_cmd("uwsm stop"))
    hl.bind("SUPER + C", send_shortcut_once("CTRL", "Insert"), { description = "Universal copy" })
    hl.bind("SUPER + V", send_shortcut_once("SHIFT", "Insert"), { description = "Universal paste" })
    hl.bind("SUPER + X", send_shortcut_once("CTRL", "X"), { description = "Universal cut" })

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
  '';
}
