_: {
  flake.modules.homeManager.desktop = {
    services.hyprpolkitagent.enable = true;

    xdg.configFile."hypr/application-style.conf".text = ''
      roundness = 0
      border_width = 2
      reduce_motion = true
    '';

    wayland.windowManager.hyprland.settings.window_rule = [
      {
        match.class = "^hyprpolkitagent$";
        float = true;
        stay_focused = true;
        border_size = 0;
        no_shadow = true;
        opaque = true;
        rounding = 0;
        no_anim = true;
        move = ["(monitor_w-window_w-18)" "44"];
      }
    ];
  };
}
