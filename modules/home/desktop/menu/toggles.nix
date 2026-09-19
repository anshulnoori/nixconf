_: {
  flake.modules.homeManager.desktop = {
    lib,
    osConfig,
    pkgs,
    ...
  }: let
    toggles = pkgs.writeShellApplication {
      name = "nixconf-toggle";
      runtimeInputs = with pkgs; [
        coreutils
        libnotify
        mako
        ripgrep
        systemd
      ];
      text = ''
        notify() {
          notify-send --app-name=nixconf-menu "$1" "''${2:-}"
        }

        case "''${1:-}" in
          nightlight)
            if systemctl --user is-active --quiet hyprsunset.service; then
              if systemctl --user stop hyprsunset.service; then
                notify "Nightlight disabled"
              else
                notify "Nightlight unavailable" "Could not stop Hyprsunset"
                exit 1
              fi
            else
              if systemctl --user start hyprsunset.service; then
                notify "Nightlight enabled" "4000 K"
              else
                notify "Nightlight unavailable" "Could not start Hyprsunset"
                exit 1
              fi
            fi
            ;;
          caffeine)
            if systemctl --user is-active --quiet nixconf-caffeine.service; then
              systemctl --user stop nixconf-caffeine.service
              notify "Decaffeinated" "Idle locking restored"
            else
              systemd-run --user --quiet --collect \
                --unit=nixconf-caffeine \
                ${pkgs.systemd}/bin/systemd-inhibit \
                  --what=idle \
                  --who=nixconf \
                  --why="Caffeine enabled" \
                  ${pkgs.coreutils}/bin/sleep infinity
              notify "Caffeinated" "Idle locking inhibited"
            fi
            ;;
          notifications)
            if makoctl mode | rg --quiet '^do-not-disturb$'; then
              makoctl mode -r do-not-disturb
              notify "Notifications resumed"
            else
              makoctl mode -a do-not-disturb
              notify "Notifications silenced"
            fi
            ;;
          bar)
            if systemctl --user is-active --quiet waybar.service; then
              systemctl --user stop waybar.service
              notify "Bar hidden"
            else
              systemctl --user start waybar.service
              notify "Bar shown"
            fi
            ;;
          *)
            printf 'Usage: nixconf-toggle <nightlight|caffeine|notifications|bar>\n' >&2
            exit 2
            ;;
        esac
      '';
    };
  in {
    home.packages = [toggles];

    services.hyprsunset = {
      enable = true;
      extraArgs = ["--temperature" "4000"];
    };

    systemd.user.services.hyprsunset = {
      Install.WantedBy = lib.mkForce [];
      Service = {
        Restart = lib.mkForce "no";
        ExecStartPost = pkgs.writeShellScript "hyprsunset-ready" ''
          for _ in {1..20}; do
            if ${osConfig.programs.hyprland.package}/bin/hyprctl hyprsunset temperature >/dev/null 2>&1; then
              exit 0
            fi
            ${pkgs.coreutils}/bin/sleep 0.1
          done
          exit 1
        '';
      };
    };
  };
}
