_: {
  flake.modules.homeManager.desktop = {
    config,
    lib,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
    lockCommand = "systemctl --user start hyprlock.service";
  in {
    stylix.targets.hyprlock.enable = false;

    programs.hyprlock = {
      enable = true;
      package = pkgs.hyprlock.overrideAttrs (previous: {
        patches =
          (previous.patches or [])
          ++ [
            (pkgs.fetchurl {
              url = "https://github.com/hyprwm/hyprlock/commit/1f337a4713e981e75ad4912cbbb5c3dccb7b6717.patch";
              hash = "sha256-iFd3l062DOSpfbg7A3EvweVf0k7kOQvUWttSNCJV2OM=";
            })
          ];
      });
      settings = {
        general = {
          hide_cursor = true;
          ignore_empty_input = true;
        };
        background = [
          {
            monitor = "";
            path = "${config.xdg.stateHome}/nixconf/wallpaper";
            blur_size = 8;
            blur_passes = 3;
            noise = 0.0117;
            contrast = 0.8917;
            brightness = 0.8172;
            vibrancy = 0.1686;
            vibrancy_darkness = 0.05;
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

    wayland.windowManager.hyprland.settings.config.misc.allow_session_lock_restore = true;

    systemd.user.services.hyprlock = {
      Unit = {
        Description = "Session lockscreen";
        After = ["graphical-session.target"];
        BindsTo = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
        StartLimitIntervalSec = 0;
      };
      Service = {
        ExecStart = lib.getExe config.programs.hyprlock.package;
        Restart = "on-failure";
        RestartSec = 2;
        TimeoutStopSec = 10;
      };
    };

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          after_sleep_cmd = "hyprctl dispatch dpms on";
          before_sleep_cmd = lockCommand;
          ignore_dbus_inhibit = false;
          lock_cmd = lockCommand;
        };
        listener = [
          {
            timeout = 300;
            on-timeout = "nixconf-screensaver start";
            on-resume = "nixconf-screensaver stop";
          }
          {
            timeout = 600;
            on-timeout = "nixconf-screensaver stop; ${lockCommand}";
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
