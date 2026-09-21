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

    hl.bind("F13", hl.dsp.exec_cmd("wlr-which-key"))
    hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("wlr-which-key --initial-keys Return"))
    hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("wlr-which-key --initial-keys space"))
    hl.bind("SUPER + ALT + SPACE", hl.dsp.exec_cmd("wlr-which-key --initial-keys Alt+space"))
    hl.bind("SUPER + Q", hl.dsp.exec_cmd("wlr-which-key --initial-keys w"))
    hl.bind("SUPER + L", hl.dsp.exec_cmd("wlr-which-key --initial-keys l"))
    hl.bind("SUPER + J", hl.dsp.exec_cmd("wlr-which-key --initial-keys j"))
    hl.bind("SUPER + K", hl.dsp.exec_cmd("wlr-which-key --initial-keys k"))
    hl.bind("SUPER + I", hl.dsp.exec_cmd("wlr-which-key --initial-keys i"))
    hl.bind("SUPER + C", send_shortcut_once("CTRL", "Insert"), { description = "Universal copy" })
    hl.bind("SUPER + V", send_shortcut_once("SHIFT", "Insert"), { description = "Universal paste" })
    hl.bind("SUPER + X", send_shortcut_once("CTRL", "X"), { description = "Universal cut" })

    hl.bind("SUPER + left", hl.dsp.exec_cmd("wlr-which-key --initial-keys Left"))
    hl.bind("SUPER + right", hl.dsp.exec_cmd("wlr-which-key --initial-keys Right"))
    hl.bind("SUPER + up", hl.dsp.exec_cmd("wlr-which-key --initial-keys Up"))
    hl.bind("SUPER + down", hl.dsp.exec_cmd("wlr-which-key --initial-keys Down"))

    local shifted_numbers = { "exclam", "at", "numbersign", "dollar", "percent", "asciicircum", "ampersand", "asterisk", "parenleft", "parenright" }
    for i = 1, 10 do
      local key = i % 10
      hl.bind("SUPER + " .. key, hl.dsp.exec_cmd("wlr-which-key --initial-keys " .. key))
      hl.bind("SUPER + SHIFT + " .. key, hl.dsp.exec_cmd("wlr-which-key --initial-keys " .. shifted_numbers[i]))
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
