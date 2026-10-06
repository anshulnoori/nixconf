_: {
  flake.modules.homeManager.desktop = {
    config,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
    dialog = pkgs.replaceVars ./hyprpolkitagent.qml {
      fontFamily = config.stylix.fonts.monospace.name;
      background = "#${colors.base00}";
      field = "#${colors.base01}";
      muted = "#${colors.base03}";
      text = "#${colors.base05}";
      error = "#${colors.base08}";
      border = "#${colors.base0D}";
    };
  in {
    services.hyprpolkitagent = {
      enable = true;
      package = pkgs.hyprpolkitagent.overrideAttrs (old: {
        postPatch =
          (old.postPatch or "")
          + ''
            cp ${dialog} qml/main.qml
          '';
      });
    };

    xdg.configFile."hypr/application-style.conf".text = ''
      roundness = 0
      border_width = 2
      reduce_motion = true
    '';

    wayland.windowManager.hyprland.settings.window_rule = [
      {
        match.title = "^Hyprland Polkit Agent$";
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
