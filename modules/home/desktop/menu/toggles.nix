_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    toggles = pkgs.writeShellApplication {
      name = "nixconf-toggle";
      runtimeInputs = with pkgs; [
        coreutils
        hyprland
        libnotify
        mako
        systemd
      ];
      text = ''
        notify() {
          notify-send --app-name=nixconf-menu "$1" "''${2:-}"
        }

        case "''${1:-}" in
          nightlight)
            if systemctl --user is-active --quiet nixconf-nightlight.service; then
              systemctl --user stop nixconf-nightlight.service
              notify "Nightlight disabled"
            else
              systemd-run --user --quiet --collect \
                --unit=nixconf-nightlight \
                ${pkgs.hyprsunset}/bin/hyprsunset

              for _ in {1..20}; do
                if hyprctl hyprsunset temperature 4000 >/dev/null 2>&1; then
                  notify "Nightlight enabled" "4000 K"
                  exit 0
                fi
                sleep 0.1
              done

              systemctl --user stop nixconf-nightlight.service
              notify "Nightlight unavailable" "Hyprsunset did not become ready"
              exit 1
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
            if makoctl mode | grep -q do-not-disturb; then
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
  };
}
