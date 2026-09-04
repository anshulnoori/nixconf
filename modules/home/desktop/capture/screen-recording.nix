_: {
  flake.modules.homeManager.desktop = {
    config,
    osConfig,
    pkgs,
    ...
  }: let
    captureScreenrecord = pkgs.writeShellApplication {
      name = "capture-screenrecord";
      runtimeInputs = with pkgs; [
        config.nixconf.desktop.capture.regionPicker
        coreutils
        ffmpeg
        gnugrep
        osConfig.programs.gpu-screen-recorder.package
        libnotify
        config.programs.mpv.finalPackage
        procps
        util-linux
        uwsm
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

        refresh_waybar() {
          pkill -RTMIN+8 -x waybar 2>/dev/null || true
        }

        finalize_recording() {
          local output="$1"
          local processed
          local video_codec=(-c:v copy)
          local args

          [[ -f "$output" ]] || return 0

          if ffprobe \
            -v error \
            -select_streams v:0 \
            -read_intervals '%+0.2' \
            -show_entries packet=flags \
            -of csv=p=0 \
            "$output" 2>/dev/null | grep -q D; then
            video_codec=(-c:v libx264 -preset veryfast -crf 20)
          fi

          args=(-y -ss 0.1 -i "$output" "''${video_codec[@]}")
          if ffprobe \
            -v error \
            -select_streams a \
            -show_entries stream=codec_type \
            -of csv=p=0 \
            "$output" 2>/dev/null | grep -q audio; then
            args+=(-af "volume=enable='lt(t,0.4)':volume=0,afade=t=in:st=0.4:d=0.05")
          fi

          processed="''${output%.mp4}-processed.mp4"
          if ffmpeg "''${args[@]}" "$processed" -loglevel error; then
            mv "$processed" "$output"
          else
            rm -f "$processed"
          fi
        }

        notify_recording_saved() {
          local output="$1"
          local thumbnail=

          if [[ -f "$output" ]]; then
            thumbnail="$(mktemp "$runtime_dir/nixconf-screenrecording-XXXXXX.png")"
            if ! ffmpeg -loglevel error -y -ss 0 -i "$output" -frames:v 1 "$thumbnail"; then
              rm -f "$thumbnail"
              thumbnail=
            fi
          fi

          (
            notify_args=(
              --app-name=nixconf-capture
              --expire-time=10000
              --action=default=Open
            )
            [[ -z "$thumbnail" ]] || notify_args+=(--icon="$thumbnail")

            action="$(notify-send \
              "''${notify_args[@]}" \
              "Screen recording saved" \
              "Click to open • $output" || true)"
            rm -f "$thumbnail"

            if [[ "$action" == "default" && -f "$output" ]]; then
              setsid uwsm app -- mpv "$output" >/dev/null 2>&1 &
            fi
          ) >/dev/null 2>&1 &
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

        select_capture_target() {
          target="$(capture-region-pick smart --match-monitor)" || return 1
          if [[ "$target" == monitor:* ]]; then
            printf '%s\n' "$target"
            return 0
          fi

          [[ "$target" =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]] || return 1
          printf 'region:%sx%s+%s+%s\n' \
            "''${BASH_REMATCH[3]}" \
            "''${BASH_REMATCH[4]}" \
            "''${BASH_REMATCH[1]}" \
            "''${BASH_REMATCH[2]}"
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
          refresh_waybar
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
          refresh_waybar
          finalize_recording "$output"
          notify_recording_saved "$output"
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
  in {
    home.packages = [captureScreenrecord];
  };
}
