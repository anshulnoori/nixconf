_: {
  flake.modules.homeManager.desktop.wayland.windowManager.hyprland.extraConfig = ''
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
    hl.window_rule({
      match = { title = "WebcamOverlay" },
      float = true,
      pin = true,
      no_initial_focus = true,
      no_dim = true,
      move = { "(monitor_w-window_w-40)", "(monitor_h-window_h-40)" },
    })
    hl.layer_rule({
      match = { namespace = "walker" },
      no_anim = true,
      animation = "none",
    })
    hl.layer_rule({
      match = { namespace = "wlr_which_key" },
      no_anim = true,
      animation = "none",
    })
  '';
}
