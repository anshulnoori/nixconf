_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    captureScreenshot = pkgs.writeShellApplication {
      name = "capture-screenshot";
      runtimeInputs = with pkgs; [
        coreutils
        grim
        hyprland
        hyprpicker
        jq
        libnotify
        procps
        satty
        slurp
        wl-clipboard
      ];
      text = ''
        output_dir="$HOME/Pictures/Screenshots"
        mkdir -p "$output_dir"

        pkill -x slurp 2>/dev/null && exit 0

        freeze_pid=
        cleanup_freeze() {
          [[ -z "$freeze_pid" ]] || kill "$freeze_pid" 2>/dev/null || true
        }
        trap cleanup_freeze EXIT

        case "''${1:-region}" in
          region)
            hyprpicker -r -z >/dev/null 2>&1 &
            freeze_pid=$!
            sleep 0.1
            selection="$(slurp 2>/dev/null || true)"
            ;;
          fullscreen)
            selection="$(hyprctl monitors -j | jq -r '
              .[] | select(.focused) |
              .x as $x | .y as $y |
              (.width / .scale | floor) as $w |
              (.height / .scale | floor) as $h |
              if .transform % 2 == 1 then
                "\($x),\($y) \($h)x\($w)"
              else
                "\($x),\($y) \($w)x\($h)"
              end
            ')"
            ;;
          *)
            printf 'Usage: capture-screenshot <region|fullscreen>\n' >&2
            exit 2
            ;;
        esac

        [[ -n "$selection" ]] || exit 0

        file="$(mktemp "$output_dir/screenshot-$(date +'%Y-%m-%d_%H-%M-%S')-XXXXXX.png")"
        if ! grim -g "$selection" "$file"; then
          rm -f "$file"
          exit 1
        fi
        cleanup_freeze
        freeze_pid=
        trap - EXIT
        wl-copy < "$file"

        (
          action="$(notify-send \
            --app-name=nixconf-capture \
            "Screenshot saved" \
            "Copied to clipboard" \
            --icon="$file" \
            --expire-time=10000 \
            --action="default=Edit" || true)"

          if [[ "$action" == "default" ]]; then
            satty \
              --filename "$file" \
              --output-filename "$file" \
              --actions-on-enter save-to-clipboard \
              --save-after-copy \
              --copy-command wl-copy
          fi
        ) >/dev/null 2>&1 &
      '';
    };
    captureScreenrecord = pkgs.writeShellApplication {
      name = "capture-screenrecord";
      runtimeInputs = with pkgs; [
        coreutils
        ffmpeg
        gnugrep
        gpu-screen-recorder
        hyprland
        hyprpicker
        jq
        libnotify
        procps
        slurp
        util-linux
        v4l-utils
      ];
      text = ''
        runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}"
        pid_file="$runtime_dir/nixconf-screenrecord.pid"
        recording_file="$runtime_dir/nixconf-screenrecord.file"
        webcam_pid_file="$runtime_dir/nixconf-screenrecord-webcam.pid"
        log_file="$runtime_dir/nixconf-screenrecord.log"
        lock_file="$runtime_dir/nixconf-screenrecord.lock"

        lock_mutation() {
          exec 9> "$lock_file"
          flock 9
        }

        lock_query() {
          exec 9> "$lock_file"
          flock --nonblock 9
        }

        notify() {
          notify-send --app-name=nixconf-capture "$1" "''${2:-}"
        }

        process_is() {
          local pid="$1"
          local expected="$2"
          local executable

          [[ "$pid" =~ ^[0-9]+$ ]] || return 1
          executable="$(readlink -f "/proc/$pid/exe" 2>/dev/null)" || return 1
          [[ "''${executable##*/}" == "$expected" ]]
        }

        stop_webcam() {
          if [[ -r "$webcam_pid_file" ]]; then
            read -r webcam_pid < "$webcam_pid_file"
            if process_is "$webcam_pid" ffplay; then
              kill "$webcam_pid" 2>/dev/null || true
            fi
          fi
          rm -f "$webcam_pid_file"
        }

        recording_active() {
          if [[ -r "$pid_file" ]]; then
            read -r recorder_pid < "$pid_file"
            if process_is "$recorder_pid" gpu-screen-recorder; then
              return 0
            fi
          fi

          rm -f "$pid_file" "$recording_file"
          stop_webcam
          return 1
        }

        get_rectangles() {
          active_workspace="$(hyprctl monitors -j | jq -r '.[] | select(.focused).activeWorkspace.id')"
          hyprctl monitors -j | jq -r --arg workspace "$active_workspace" '
            .[] | select(.activeWorkspace.id == ($workspace | tonumber)) |
            .x as $x | .y as $y |
            (.width / .scale | floor) as $w |
            (.height / .scale | floor) as $h |
            if .transform % 2 == 1 then
              "\($x),\($y) \($h)x\($w)"
            else
              "\($x),\($y) \($w)x\($h)"
            end
          '
          hyprctl clients -j | jq -r --arg workspace "$active_workspace" '
            .[] | select(.workspace.id == ($workspace | tonumber)) |
            "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"
          '
        }

        select_capture_target() {
          rectangles="$(get_rectangles)"
          hyprpicker -r -z >/dev/null 2>&1 &
          picker_pid=$!
          sleep 0.1
          selection="$(printf '%s\n' "$rectangles" | slurp 2>/dev/null || true)"
          kill "$picker_pid" 2>/dev/null || true

          if [[ ! "$selection" =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]]; then
            return 1
          fi

          selection_x="''${BASH_REMATCH[1]}"
          selection_y="''${BASH_REMATCH[2]}"
          selection_width="''${BASH_REMATCH[3]}"
          selection_height="''${BASH_REMATCH[4]}"

          if (( selection_width * selection_height < 20 )); then
            while IFS= read -r rectangle; do
              [[ "$rectangle" =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]] || continue
              rectangle_x="''${BASH_REMATCH[1]}"
              rectangle_y="''${BASH_REMATCH[2]}"
              rectangle_width="''${BASH_REMATCH[3]}"
              rectangle_height="''${BASH_REMATCH[4]}"
              if (( selection_x >= rectangle_x && selection_x < rectangle_x + rectangle_width && selection_y >= rectangle_y && selection_y < rectangle_y + rectangle_height )); then
                selection_x="$rectangle_x"
                selection_y="$rectangle_y"
                selection_width="$rectangle_width"
                selection_height="$rectangle_height"
                break
              fi
            done <<< "$rectangles"
          fi

          monitor="$(hyprctl monitors -j | jq -r \
            --argjson x "$selection_x" \
            --argjson y "$selection_y" \
            --argjson width "$selection_width" \
            --argjson height "$selection_height" '
              .[] |
              select(
                .x == $x and
                .y == $y and
                (
                  if .transform % 2 == 1 then
                    (.height / .scale | floor) == $width and
                    (.width / .scale | floor) == $height
                  else
                    (.width / .scale | floor) == $width and
                    (.height / .scale | floor) == $height
                  end
                )
              ) |
              .name
            ' | head -n 1)"

          if [[ -n "$monitor" ]]; then
            printf 'monitor:%s\n' "$monitor"
          else
            printf 'region:%sx%s+%s+%s\n' \
              "$selection_width" "$selection_height" "$selection_x" "$selection_y"
          fi
        }

        start_webcam() {
          webcam_device=
          shopt -s nullglob
          for candidate in /dev/video*; do
            device_name="$(cat "/sys/class/video4linux/''${candidate##*/}/name" 2>/dev/null || true)"
            if grep -Eqi 'OBS Cam|loopback' <<< "$device_name"; then
              continue
            fi
            if v4l2-ctl --all --device "$candidate" 2>/dev/null | grep -q 'Video Capture'; then
              webcam_device="$candidate"
              break
            fi
          done
          shopt -u nullglob

          if [[ -z "$webcam_device" ]]; then
            notify "No webcam found"
            return 1
          fi

          setsid ffplay \
            -f v4l2 \
            -framerate 30 \
            -i "$webcam_device" \
            -vf 'scale=360:-1' \
            -window_title WebcamOverlay \
            -noborder \
            -fflags nobuffer \
            -flags low_delay \
            -an \
            -loglevel quiet \
            >/dev/null 2>&1 &
          webcam_pid=$!
          printf '%s\n' "$webcam_pid" > "$webcam_pid_file"
          sleep 1

          if ! kill -0 "$webcam_pid" 2>/dev/null; then
            stop_webcam
            notify "Webcam unavailable" "$webcam_device could not be opened"
            return 1
          fi
        }

        start_recording() {
          mode="$1"
          if recording_active; then
            notify "Screen recording already active"
            exit 1
          fi

          target="$(select_capture_target)" || exit 0
          capture_args=()
          case "$target" in
            monitor:*) capture_args=(-w "''${target#monitor:}") ;;
            region:*) capture_args=(-w region -region "''${target#region:}") ;;
            *) exit 1 ;;
          esac

          audio_args=()
          case "$mode" in
            no-audio) ;;
            desktop-audio) audio_args=(-a default_output -ac aac) ;;
            microphone) audio_args=(-a 'default_output|default_input' -ac aac) ;;
            webcam)
              audio_args=(-a 'default_output|default_input' -ac aac)
              start_webcam || exit 1
              ;;
            *)
              printf 'Usage: capture-screenrecord <no-audio|desktop-audio|microphone|webcam|stop|active|inactive>\n' >&2
              exit 2
              ;;
          esac

          output_dir="$HOME/Videos"
          mkdir -p "$output_dir"
          output="$output_dir/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"

          setsid gpu-screen-recorder \
            "''${capture_args[@]}" \
            -k auto \
            -f 60 \
            -fm cfr \
            -fallback-cpu-encoding yes \
            "''${audio_args[@]}" \
            -o "$output" \
            > "$log_file" 2>&1 &
          recorder_pid=$!
          sleep 1

          if ! kill -0 "$recorder_pid" 2>/dev/null; then
            wait "$recorder_pid" || true
            stop_webcam
            notify "Screen recording failed" "See $log_file"
            exit 1
          fi

          printf '%s\n' "$recorder_pid" > "$pid_file"
          printf '%s\n' "$output" > "$recording_file"
          notify "Screen recording started" "Select Stop Screen Recording when finished"
        }

        stop_recording() {
          if ! recording_active; then
            notify "No screen recording is active"
            exit 1
          fi

          read -r recorder_pid < "$pid_file"
          output=
          [[ ! -r "$recording_file" ]] || read -r output < "$recording_file"
          kill -INT "$recorder_pid"

          for _ in {1..300}; do
            process_is "$recorder_pid" gpu-screen-recorder || break
            sleep 0.1
          done

          if process_is "$recorder_pid" gpu-screen-recorder; then
            notify "Screen recording is still finalizing" "$output"
            return 0
          fi

          stop_webcam
          rm -f "$pid_file" "$recording_file"
          notify "Screen recording saved" "$output"
        }

        case "''${1:-}" in
          active)
            lock_query && recording_active
            ;;
          inactive)
            lock_query && ! recording_active
            ;;
          stop)
            lock_mutation
            stop_recording
            ;;
          no-audio | desktop-audio | microphone | webcam)
            lock_mutation
            start_recording "$1"
            ;;
          *)
            printf 'Usage: capture-screenrecord <no-audio|desktop-audio|microphone|webcam|stop|active|inactive>\n' >&2
            exit 2
            ;;
        esac
      '';
    };
    captureText = pkgs.writeShellApplication {
      name = "capture-text";
      runtimeInputs = with pkgs; [
        coreutils
        grim
        hyprpicker
        libnotify
        slurp
        tesseract5
        wl-clipboard
      ];
      text = ''
        hyprpicker -r -z >/dev/null 2>&1 &
        freeze_pid=$!
        trap 'kill "$freeze_pid" 2>/dev/null || true' EXIT
        sleep 0.1
        selection="$(slurp 2>/dev/null || true)"
        [[ -n "$selection" ]] || exit 0

        text="$(grim -g "$selection" - | tesseract stdin stdout \
          --oem 1 \
          --psm 6 \
          -l eng \
          --dpi 300 \
          -c preserve_interword_spaces=1 \
          2>/dev/null)"
        [[ -n "$text" ]] || exit 1

        printf '%s' "$text" | wl-copy
        notify-send --app-name=nixconf-capture "Text copied"
      '';
    };
    captureQr = pkgs.writeShellApplication {
      name = "capture-qr";
      runtimeInputs = with pkgs; [
        coreutils
        grim
        hyprpicker
        libnotify
        slurp
        wl-clipboard
        zbar
      ];
      text = ''
        hyprpicker -r -z >/dev/null 2>&1 &
        freeze_pid=$!
        trap 'kill "$freeze_pid" 2>/dev/null || true' EXIT
        sleep 0.1
        selection="$(slurp 2>/dev/null || true)"
        [[ -n "$selection" ]] || exit 0

        value="$(grim -g "$selection" - | zbarimg --quiet --raw - 2>/dev/null | head -n 1)"
        if [[ -z "$value" ]]; then
          notify-send --app-name=nixconf-capture "No QR code found"
          exit 1
        fi

        printf '%s' "$value" | wl-copy
        notify-send --app-name=nixconf-capture "QR code copied" "$value"
      '';
    };
    captureColor = pkgs.writeShellApplication {
      name = "capture-color";
      runtimeInputs = with pkgs; [
        hyprpicker
        libnotify
        procps
        wl-clipboard
      ];
      text = ''
        if pkill -x hyprpicker 2>/dev/null; then
          exit 0
        fi

        color="$(hyprpicker)"
        [[ -n "$color" ]] || exit 0
        printf '%s' "$color" | wl-copy
        notify-send --app-name=nixconf-capture "Color copied" "$color"
      '';
    };
  in {
    home.packages = [
      captureColor
      captureQr
      captureScreenrecord
      captureScreenshot
      captureText
    ];
  };
}
