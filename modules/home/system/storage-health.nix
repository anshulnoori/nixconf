_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    storageHealth = pkgs.writeShellApplication {
      name = "nixconf-storage-health";
      runtimeInputs = with pkgs; [
        bat
        coreutils
        jq
        libnotify
        procps
        util-linux
      ];
      text = ''
        status_file=/var/lib/nixconf-storage-health/status.json
        report_file=/var/lib/nixconf-storage-health/report.txt
        state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/nixconf"
        acknowledgement_file="$state_dir/storage-health-acknowledged"
        notification_file="$state_dir/storage-health-notified"
        runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}"

        status_value() {
          jq -r "$1 // empty" "$status_file" 2>/dev/null
        }

        signal_waybar() {
          pkill -RTMIN+9 -x waybar 2>/dev/null || true
        }

        case "''${1:-waybar}" in
          waybar)
            mkdir -p "$state_dir"
            exec 9> "$runtime_dir/nixconf-storage-health.lock"
            flock 9

            if [[ "$(status_value '.state')" != warning ]]; then
              rm -f "$acknowledgement_file" "$notification_file"
              printf '{"text":""}\n'
              exit 0
            fi

            issue_id="$(status_value '.id')"
            if [[ -r "$acknowledgement_file" ]] \
              && [[ "$(cat "$acknowledgement_file")" == "$issue_id" ]]; then
              printf '{"text":""}\n'
              exit 0
            fi

            if [[ ! -r "$notification_file" ]] \
              || [[ "$(cat "$notification_file")" != "$issue_id" ]]; then
              summary="$(status_value '.summary')"
              details="$(jq -r '.issues | join("\n")' "$status_file")"
              printf -v body '%s\n%s' "$summary" "$details"
              notify-send \
                --app-name=nixconf-storage-health \
                --urgency=critical \
                --expire-time=0 \
                "Storage health warning" \
                "$body"
              printf '%s\n' "$issue_id" > "$notification_file"
            fi

            jq -c '{
              text: "󰋊",
              class: "warning",
              tooltip: ([.summary] + .issues + ["", "Left click: open report", "Right click: acknowledge"] | join("\n"))
            }' "$status_file"
            ;;
          open)
            if [[ -r "$report_file" ]]; then
              exec present-terminal "Storage Health" \
                bat --plain --paging=always "$report_file"
            fi
            notify-send --app-name=nixconf-storage-health \
              "Storage health unavailable" \
              "The first system health check has not completed yet."
            ;;
          acknowledge)
            if [[ "$(status_value '.state')" == warning ]]; then
              mkdir -p "$state_dir"
              status_value '.id' > "$acknowledgement_file"
              signal_waybar
            fi
            ;;
          *)
            printf 'Usage: nixconf-storage-health [waybar|open|acknowledge]\n' >&2
            exit 2
            ;;
        esac
      '';
    };
  in {
    home.packages = [storageHealth];
  };
}
