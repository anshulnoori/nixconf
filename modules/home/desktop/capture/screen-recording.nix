_: {
  flake.modules.nixos.desktop.programs.gpu-screen-recorder.enable = true;

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
        osConfig.programs.gpu-screen-recorder.package
        libnotify
        config.programs.mpv.finalPackage
        procps
        ripgrep
        systemd
        uwsm
      ];
      text = ''
        unit="''${CAPTURE_SCREENRECORD_UNIT:-nixconf-screenrecord.service}"
        session_target="''${CAPTURE_SCREENRECORD_SESSION_TARGET:-graphical-session.target}"
        runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}"
        log_file="$runtime_dir/nixconf-screenrecord.log"
        recorder="''${CAPTURE_SCREENRECORD_RECORDER:-gpu-screen-recorder}"
        picker="''${CAPTURE_SCREENRECORD_PICKER:-capture-region-pick}"
        notifier="''${CAPTURE_SCREENRECORD_NOTIFIER:-notify-send}"

        notify() {
          "$notifier" --app-name=nixconf-capture "$1" "''${2:-}"
        }

        refresh_waybar() {
          pkill -RTMIN+8 -x waybar 2>/dev/null || true
        }

        recording_active() {
          systemctl --user --quiet is-active "$unit"
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
            "$output" 2>/dev/null | rg --quiet D; then
            video_codec=(-c:v libx264 -preset veryfast -crf 20)
          fi

          args=(-y -ss 0.1 -i "$output" "''${video_codec[@]}")
          if ffprobe \
            -v error \
            -select_streams a \
            -show_entries stream=codec_type \
            -of csv=p=0 \
            "$output" 2>/dev/null | rg --quiet audio; then
            args+=(-af "volume=enable='lt(t,0.4)':volume=0,afade=t=in:st=0.4:d=0.05")
          fi

          processed="''${output%.mp4}-processed.mp4"
          if ffmpeg "''${args[@]}" "$processed" -loglevel error; then
            mv "$processed" "$output"
          else
            rm -f "$processed"
            return 1
          fi
        }

        notify_recording_saved() {
          local output="$1"
          local thumbnail=
          local action
          local notify_args

          if [[ -f "$output" ]]; then
            thumbnail="$(mktemp "$runtime_dir/nixconf-screenrecording-XXXXXX.png")"
            if ! ffmpeg -loglevel error -y -ss 0 -i "$output" -frames:v 1 "$thumbnail"; then
              rm -f "$thumbnail"
              thumbnail=
            fi
          fi

          notify_args=(
            --app-name=nixconf-capture
            --expire-time=10000
            --action=default=Open
          )
          [[ -z "$thumbnail" ]] || notify_args+=(--icon="$thumbnail")
          action="$("$notifier" "''${notify_args[@]}" "Screen recording saved" "Click to open • $output" || true)"
          rm -f "$thumbnail"

          if [[ "$action" == "default" && -f "$output" ]]; then
            uwsm app -- mpv "$output" >/dev/null 2>&1 &
          fi
        }

        select_capture_target() {
          local target
          target="$("$picker" smart --match-monitor)" || return 1
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

        run_recording_unit() {
          local mode="$1" target="$2" output="$3"
          local recorder_pid status stopping
          local capture_args audio_args
          recorder_pid=
          status=0
          stopping=0

          stop_children() {
            stopping=1
            [[ -z "''${recorder_pid:-}" ]] || kill -INT "$recorder_pid" 2>/dev/null || true
          }
          trap stop_children INT TERM

          capture_args=()
          case "$target" in
            monitor:*) capture_args=(-w "''${target#monitor:}") ;;
            region:*) capture_args=(-w region -region "''${target#region:}") ;;
            *) return 1 ;;
          esac

          audio_args=()
          case "$mode" in
            no-audio) ;;
            desktop-audio) audio_args=(-a default_output -ac aac) ;;
            microphone) audio_args=(-a 'default_output|default_input' -ac aac) ;;
          esac

          (( stopping == 0 )) || return 0

          env --default-signal=INT "$recorder" \
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
          if (( stopping == 0 )) && kill -0 "$recorder_pid" 2>/dev/null; then
            systemd-notify --ready
          fi
          while true; do
            if wait "$recorder_pid"; then
              status=0
              break
            else
              status=$?
            fi
            kill -0 "$recorder_pid" 2>/dev/null || break
          done
          trap - INT TERM

          refresh_waybar

          if (( status == 0 )) && [[ -s "$output" ]] &&
            ffprobe -v error -select_streams v:0 -show_entries stream=codec_type -of csv=p=0 "$output" | rg --quiet '^video$' &&
            finalize_recording "$output"; then
            systemd-run --user --quiet --collect \
              --unit="''${unit%.service}-saved-$(date +%s%N).service" \
              --property=Type=exec \
              --setenv="HOME=$HOME" \
              --setenv="XDG_RUNTIME_DIR=$runtime_dir" \
              --setenv="WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-}" \
              --setenv="DISPLAY=''${DISPLAY:-}" \
              --setenv="HYPRLAND_INSTANCE_SIGNATURE=''${HYPRLAND_INSTANCE_SIGNATURE:-}" \
              --setenv="CAPTURE_SCREENRECORD_NOTIFIER=$notifier" \
              "$0" __notify "$output" >/dev/null
          else
            notify "Screen recording failed" "See $log_file"
            status=1
          fi
          return "$status"
        }

        start_recording() {
          local mode="$1" target output
          local -a environment

          if recording_active; then
            notify "Screen recording already active"
            return 1
          fi
          target="$(select_capture_target)" || return 0
          output="$HOME/Videos/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"
          mkdir -p "''${output%/*}"

          environment=(
            --setenv="HOME=$HOME"
            --setenv="XDG_RUNTIME_DIR=$runtime_dir"
            --setenv="WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-}"
            --setenv="DISPLAY=''${DISPLAY:-}"
            --setenv="HYPRLAND_INSTANCE_SIGNATURE=''${HYPRLAND_INSTANCE_SIGNATURE:-}"
            --setenv="CAPTURE_SCREENRECORD_UNIT=$unit"
            --setenv="CAPTURE_SCREENRECORD_SESSION_TARGET=$session_target"
          )
          [[ -z "''${CAPTURE_SCREENRECORD_RECORDER:-}" ]] || environment+=(--setenv="CAPTURE_SCREENRECORD_RECORDER=$recorder")
          [[ -z "''${CAPTURE_SCREENRECORD_NOTIFIER:-}" ]] || environment+=(--setenv="CAPTURE_SCREENRECORD_NOTIFIER=$notifier")

          if ! systemd-run --user --quiet --collect --unit="$unit" \
            --property=Type=notify \
            --property=NotifyAccess=all \
            --property=TimeoutStartSec=10 \
            --property=KillMode=mixed \
            --property=KillSignal=SIGINT \
            --property=TimeoutStopSec=35 \
            --property="After=$session_target" \
            --property="BindsTo=$session_target" \
            --property="PartOf=$session_target" \
            "''${environment[@]}" \
            "$0" __run "$mode" "$target" "$output"; then
            notify "Screen recording failed" "Could not start $unit"
            return 1
          fi

          refresh_waybar
          notify "Screen recording started" "Select Stop Screen Recording when finished"
        }

        case "''${1:-}" in
          active) recording_active ;;
          inactive) ! recording_active ;;
          stop)
            if ! recording_active; then
              notify "No screen recording is active"
              exit 1
            fi
            systemctl --user stop "$unit"
            ;;
          no-audio | desktop-audio | microphone) start_recording "$1" ;;
          __run) shift; run_recording_unit "$@" ;;
          __notify) shift; notify_recording_saved "$1" ;;
          *)
            printf 'Usage: capture-screenrecord <no-audio|desktop-audio|microphone|stop|active|inactive>\n' >&2
            exit 2
            ;;
        esac
      '';
    };
  in {
    home.packages = [captureScreenrecord];
  };
}
