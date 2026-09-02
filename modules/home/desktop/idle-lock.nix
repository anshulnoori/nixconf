_: {
  flake.modules.homeManager.desktop = {config, ...}: let
    colors = config.lib.stylix.colors;
  in {
    stylix.targets.hyprlock.enable = false;

    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          hide_cursor = true;
          ignore_empty_input = true;
        };
        background = [
          {
            monitor = "";
            path = "${config.xdg.stateHome}/nixconf/wallpaper";
            blur_size = 16;
            blur_passes = 3;
            noise = 0.0;
            contrast = 1.0;
            brightness = 1.0;
            vibrancy = 0.0;
          }
        ];
        animations.enabled = false;
        input-field = [
          {
            monitor = "";
            size = "400, 60";
            position = "0, 0";
            halign = "center";
            valign = "center";
            inner_color = "rgba(${colors.base00}cc)";
            outer_color = "rgb(${colors.base05})";
            outline_thickness = 4;
            font_family = "JetBrainsMono Nerd Font";
            font_size = 16;
            font_color = "rgb(${colors.base05})";
            placeholder_text = "Enter Password";
            check_color = "rgb(${colors.base0D})";
            fail_text = "<i>$FAIL ($ATTEMPTS)</i>";
            dots_center = true;
            fade_on_empty = false;
            rounding = 0;
            shadow_passes = 0;
          }
        ];
      };
    };

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          after_sleep_cmd = "hyprctl dispatch dpms on";
          before_sleep_cmd = "pidof hyprlock || hyprlock";
          ignore_dbus_inhibit = false;
          lock_cmd = "pidof hyprlock || hyprlock";
        };
        listener = [
          {
            timeout = 300;
            on-timeout = "nixconf-screensaver start";
            on-resume = "nixconf-screensaver stop";
          }
          {
            timeout = 600;
            on-timeout = "nixconf-screensaver stop; pidof hyprlock || hyprlock";
          }
          {
            timeout = 1200;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };
  };
}
