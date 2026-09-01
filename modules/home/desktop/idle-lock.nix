{inputs, ...}: {
  flake.modules.homeManager.desktop = {config, ...}: let
    colors = config.lib.stylix.colors;
    wallpaper = "${inputs.omarchy-rice}/themes/gruvbox/backgrounds/1-the-backwater.jpg";
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
            path = wallpaper;
            blur_passes = 3;
          }
        ];
        animations.enabled = false;
        input-field = [
          {
            monitor = "";
            size = "650, 100";
            position = "0, 0";
            halign = "center";
            valign = "center";
            inner_color = "rgba(${colors.base00}cc)";
            outer_color = "rgb(${colors.base05})";
            outline_thickness = 4;
            font_family = "JetBrainsMono Nerd Font";
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
            timeout = 600;
            on-timeout = "hyprlock";
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
