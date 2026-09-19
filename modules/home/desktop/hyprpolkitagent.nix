_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    services.hyprpolkitagent.enable = true;

    systemd.user.services.hyprpolkitagent.Service.Environment = [
      "QT_QPA_PLATFORMTHEME=qt6ct"
      "QT_PLUGIN_PATH=${pkgs.qt6Packages.qt6ct}/lib/qt-6/plugins"
      "QT_SCALE_FACTOR=0.85"
    ];

    xdg.configFile."hypr/application-style.conf".text = ''
      roundness = 0
      border_width = 2
      reduce_motion = true
    '';

    wayland.windowManager.hyprland.settings.window_rule = [
      {
        match.title = "^Hyprland Polkit Agent$";
        float = true;
        rounding = 0;
        no_anim = true;
        move = ["(monitor_w-window_w-20)" "60"];
      }
    ];
  };
}
