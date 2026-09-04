{inputs, ...}: {
  flake.modules.nixos.desktop = {
    config,
    lib,
    pkgs,
    ...
  }: let
    theme = import ./_theme.nix {
      inherit config inputs lib pkgs;
    };
  in {
    boot = {
      consoleLogLevel = 0;
      initrd.verbose = false;
      kernelParams = [
        "quiet"
        "systemd.show_status=false"
        "rd.systemd.show_status=false"
        "udev.log_level=0"
        "rd.udev.log_level=0"
        "vt.global_cursor_default=0"
      ];
      plymouth = {
        inherit (theme) font;
        enable = true;
        showDelay = 0;
        theme = theme.themeName;
        themePackages = [theme.theme];
      };
    };

    boot.initrd.systemd = {
      storePaths = [
        theme.prepareBackground
        theme.hyprlockBlur
        pkgs.hyprlock.src
        theme.wallpaper
      ];
      services = {
        nixconf-boot-background = {
          description = "Render Hyprlock-matched Plymouth background";
          wantedBy = ["sysinit.target"];
          before = ["plymouth-start.service"];
          after = [
            "systemd-udev-trigger.service"
            "systemd-udevd.service"
          ];
          unitConfig.DefaultDependencies = false;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${theme.prepareBackground}/bin/nixconf-prepare-boot-background";
            TimeoutStartSec = "15s";
          };
        };
        plymouth-start = {
          wants = ["nixconf-boot-background.service"];
          after = ["nixconf-boot-background.service"];
        };
      };
    };
  };
}
