_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    showQr = pkgs.writeShellApplication {
      name = "nixconf-show-qr";
      runtimeInputs = with pkgs; [
        qrencode
        wl-clipboard
      ];
      text = ''
        clear
        if ! wl-paste --no-newline | qrencode -t ANSIUTF8; then
          printf 'Clipboard does not contain text that can be encoded.\n' >&2
          exit 1
        fi

        printf '\nPress any key to close...'
        read -r -s -n 1
      '';
    };
    share = pkgs.writeShellApplication {
      name = "nixconf-share";
      runtimeInputs = with pkgs; [
        coreutils
        findutils
        kitty
        localsend
        util-linux
        uwsm
        wl-clipboard
        zenity
      ];
      text = ''
        launch_localsend() {
          exec setsid uwsm app -- localsend_app "$@"
        }

        case "''${1:-}" in
          clipboard)
            cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/nixconf/share"
            mkdir -p "$cache_dir"
            find "$cache_dir" -type f -mtime +1 -delete
            file="$(mktemp "$cache_dir/clipboard-XXXXXX.txt")"
            chmod 600 "$file"
            wl-paste --no-newline > "$file"
            launch_localsend "$file"
            ;;
          file)
            file="$(zenity --file-selection --title='Share file' 2>/dev/null || true)"
            [[ -n "$file" ]] || exit 0
            launch_localsend "$file"
            ;;
          folder)
            folder="$(zenity --file-selection --directory --title='Share folder' 2>/dev/null || true)"
            [[ -n "$folder" ]] || exit 0
            launch_localsend "$folder"
            ;;
          receive)
            launch_localsend
            ;;
          qr)
            exec setsid uwsm app -- kitty \
              --class TUI.float \
              --title 'QR Code' \
              ${showQr}/bin/nixconf-show-qr
            ;;
          *)
            printf 'Usage: nixconf-share <clipboard|file|folder|receive|qr>\n' >&2
            exit 2
            ;;
        esac
      '';
    };
  in {
    home.packages = [share];
  };
}
