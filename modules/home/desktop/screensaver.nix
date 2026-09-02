_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    screensaverRunner = pkgs.writeShellApplication {
      name = "nixconf-screensaver-run";
      runtimeInputs = with pkgs; [
        coreutils
        hyprland
        jq
        terminaltexteffects
      ];
      text = ''
        effect_pid=
        input_file="''${XDG_RUNTIME_DIR:-/tmp}/nixconf-screensaver-$$.txt"

        screensaver_in_focus() {
          hyprctl activewindow -j | jq -e '.class == "org.nixconf.screensaver"' >/dev/null 2>&1
        }

        screensaver_present() {
          hyprctl clients -j | jq -e 'any(.[]; .class == "org.nixconf.screensaver")' >/dev/null 2>&1
        }

        exit_screensaver() {
          [[ -z "$effect_pid" ]] || kill "$effect_pid" 2>/dev/null || true
          rm -f "$input_file"
          hyprctl keyword cursor:invisible false >/dev/null 2>&1 || true
          pkill -f org.nixconf.screensaver 2>/dev/null || true
          exit 0
        }

        trap exit_screensaver INT TERM HUP QUIT
        printf '\033]11;rgb:00/00/00\007'
        hyprctl keyword cursor:invisible true >/dev/null 2>&1 || true

        for _ in {1..30}; do
          screensaver_present && break
          sleep 0.1
        done
        screensaver_present || exit 1
        sleep 0.4

        while true; do
          printf '\n%s\n%s\n' "$(date '+%A, %B %-d')" "$(date '+%-I:%M %p')" > "$input_file"
          tte -i "$input_file" \
            --frame-rate 120 \
            --canvas-width 0 \
            --canvas-height 0 \
            --reuse-canvas \
            --anchor-canvas c \
            --anchor-text c \
            --random-effect \
            --exclude-effects print \
            --no-eol \
            --no-restore-cursor &
          effect_pid=$!

          while kill -0 "$effect_pid" 2>/dev/null; do
            if read -r -n 1 -t 1 || ! screensaver_in_focus; then
              exit_screensaver
            fi
          done

          wait "$effect_pid" || true
          effect_pid=
        done
      '';
    };
    screensaver = pkgs.writeShellApplication {
      name = "nixconf-screensaver";
      runtimeInputs = with pkgs; [
        coreutils
        hyprland
        jq
        kitty
        libnotify
        procps
        util-linux
        uwsm
        walker
      ];
      text = ''
        state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/nixconf"
        runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}"
        disabled_file="$state_dir/screensaver-disabled"
        lock_file="$runtime_dir/nixconf-screensaver.lock"

        mkdir -p "$state_dir"
        exec 9> "$lock_file"
        flock 9

        stop_screensaver() {
          pkill -f '[n]ixconf-screensaver-run' 2>/dev/null || true
          hyprctl keyword cursor:invisible false >/dev/null 2>&1 || true
        }

        case "''${1:-start}" in
          stop)
            stop_screensaver
            ;;
          toggle)
            if [[ -e "$disabled_file" ]]; then
              rm -f "$disabled_file"
              notify-send --app-name=nixconf-menu "Screensaver enabled"
            else
              touch "$disabled_file"
              stop_screensaver
              notify-send --app-name=nixconf-menu "Screensaver disabled"
            fi
            ;;
          start | force)
            if [[ "''${1:-start}" != force && -e "$disabled_file" ]]; then
              exit 0
            fi

            pgrep -f '[n]ixconf-screensaver-run' >/dev/null && exit 0
            walker -q >/dev/null 2>&1 || true

            focused="$(hyprctl monitors -j | jq -r '.[] | select(.focused).name')"
            mapfile -t monitors < <(hyprctl monitors -j | jq -r '.[].name')
            for monitor in "''${monitors[@]}"; do
              hyprctl dispatch focusmonitor "$monitor" >/dev/null
              setsid uwsm app -- kitty \
                --class org.nixconf.screensaver \
                --override font_size=18 \
                --override window_padding_width=0 \
                ${screensaverRunner}/bin/nixconf-screensaver-run \
                >/dev/null 2>&1 &
            done

            [[ -z "$focused" ]] || hyprctl dispatch focusmonitor "$focused" >/dev/null

            for _ in {1..20}; do
              pgrep -f '[n]ixconf-screensaver-run' >/dev/null && exit 0
              sleep 0.1
            done

            notify-send --app-name=nixconf-menu "Screensaver unavailable" "No screensaver window started"
            exit 1
            ;;
          *)
            printf 'Usage: nixconf-screensaver [start|force|stop|toggle]\n' >&2
            exit 2
            ;;
        esac
      '';
    };
  in {
    home.packages = [screensaver];

    wayland.windowManager.hyprland.extraConfig = ''
      hl.window_rule({
        match = { class = "org.nixconf.screensaver" },
        fullscreen = true,
        float = true,
      })
    '';
  };
}
