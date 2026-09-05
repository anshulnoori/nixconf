_: {
  flake.modules.nixos.desktop = {
    config,
    lib,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
    wallpaper = "${builtins.head config.boot.plymouth.themePackages}/share/plymouth/themes/${config.boot.plymouth.theme}/background.png";
    themeConfig = (pkgs.formats.ini {}).generate "theme.conf" {
      General = {
        Background = wallpaper;
        BackgroundColor = "#${colors.base00}";
        FieldColor = "#cc${colors.base00}";
        Foreground = "#${colors.base05}";
        CheckingColor = "#${colors.base0D}";
        FailureColor = "#${colors.base08}";
        User = "mvs";
        Session = "hyprland-uwsm.desktop";
      };
    };
    theme = pkgs.runCommand "hyprlock-sddm-theme" {} ''
      themeDir="$out/share/sddm/themes/hyprlock"
      mkdir -p "$themeDir"
      cp ${./sddm/Main.qml} "$themeDir/Main.qml"
      cp ${themeConfig} "$themeDir/theme.conf"
      cat > "$themeDir/metadata.desktop" <<'EOF'
      [SddmGreeterTheme]
      Name=Hyprlock
      Description=Single-user login matching Hyprlock and Plymouth
      Type=sddm-theme
      MainScript=Main.qml
      ConfigFile=theme.conf
      Theme-Id=hyprlock
      Theme-API=2.0
      QtVersion=6
      EOF
    '';
    plymouth = lib.getExe' config.boot.plymouth.package "plymouth";
    quitPlymouth = pkgs.writeShellApplication {
      name = "quit-plymouth-after-desktop";
      runtimeInputs = with pkgs; [
        coreutils
        procps
      ];
      text = ''
        if ! ${plymouth} --ping; then
          exit 0
        fi

        desktop_ready=false
        for _ in {1..300}; do
          if pgrep -u mvs -x Hyprland >/dev/null && pgrep -u mvs -x swaybg >/dev/null; then
            desktop_ready=true
            sleep 0.25
            break
          fi
          sleep 0.1
        done

        if [[ "$desktop_ready" == true ]]; then
          exec ${plymouth} quit --retain-splash
        fi

        exec ${plymouth} quit
      '';
    };
  in {
    environment.systemPackages = [theme];
    fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];

    services.displayManager = {
      defaultSession = "hyprland-uwsm";
      # Preserve boot autologin, but require a password after `uwsm stop`.
      autoLogin = {
        enable = true;
        user = "mvs";
      };
      sddm = {
        enable = true;
        wayland.enable = true;
        theme = "hyprlock";
        autoLogin.relogin = false;
      };
    };

    systemd.services = {
      display-manager = {
        # Keep the retained splash until the desktop is ready, not vice versa.
        after = lib.mkForce [
          "acpid.service"
          "systemd-logind.service"
          "systemd-user-sessions.service"
          "autovt@tty1.service"
        ];
        serviceConfig.ExecStartPre = "-${plymouth} deactivate";
      };
      plymouth-quit-wait.wantedBy = lib.mkForce [];
      plymouth-quit = {
        after = ["display-manager.service"];
        wantedBy = lib.mkForce ["graphical.target"];
        serviceConfig = {
          Type = "simple";
          ExecStart = lib.mkForce [
            ""
            "${quitPlymouth}/bin/quit-plymouth-after-desktop"
          ];
          TimeoutStartSec = "35s";
        };
      };
    };

    security.pam.services.hyprlock = {};
  };
}
