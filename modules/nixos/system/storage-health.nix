_: {
  flake.modules.nixos.base = {pkgs, ...}: let
    storageHealthCheck = pkgs.writeShellApplication {
      name = "nixconf-storage-health-check";
      runtimeInputs = with pkgs; [
        btrfs-progs
        coreutils
        jq
        nvme-cli
      ];
      text = ''
        state_dir=/var/lib/nixconf-storage-health
        status_file="$state_dir/status.json"
        report_file="$state_dir/report.txt"
        counters_file="$state_dir/counters.json"
        temporary_status="$state_dir/status.json.new"
        temporary_report="$state_dir/report.txt.new"
        temporary_counters="$state_dir/counters.json.new"
        issues=()

        mkdir -p "$state_dir"
        previous_counters='{}'
        if [[ -r "$counters_file" ]] && jq -e 'type == "object"' "$counters_file" >/dev/null; then
          previous_counters="$(cat "$counters_file")"
        fi
        current_counters='{}'

        add_issue() {
          issues+=("$1")
        }

        {
          printf 'Storage health report — %s\n\n' "$(date --iso-8601=seconds)"

          printf '== Btrfs device stats ==\n'
          if ! btrfs device stats --check /; then
            add_issue "Btrfs reports device errors"
          fi

          printf '\n== Root filesystem usage ==\n'
          df -h /
          used_percent="$(df --output=pcent / | tail -n 1 | tr -cd '0-9')"
          if [[ -n "$used_percent" ]] && ((used_percent >= 90)); then
            add_issue "Root filesystem is ''${used_percent}% full"
          fi

          shopt -s nullglob
          devices=(/dev/nvme*n1)
          if ((''${#devices[@]} == 0)); then
            add_issue "No NVMe namespace was detected"
          fi

          for device in "''${devices[@]}"; do
            device_name="$(basename "$device")"
            printf '\n== %s identity ==\n' "$device"
            if ! nvme id-ctrl "$device"; then
              add_issue "Unable to read $device identity"
            fi

            printf '\n== %s SMART log ==\n' "$device"
            if ! smart_json="$(nvme smart-log --output-format=json "$device")"; then
              add_issue "Unable to read $device SMART health"
              continue
            fi
            jq . <<< "$smart_json"

            critical_warning="$(jq -r '(.critical_warning // 0) | tonumber? // 0' <<< "$smart_json")"
            available_spare="$(jq -r '(.avail_spare // .available_spare // 100) | tonumber? // 100' <<< "$smart_json")"
            spare_threshold="$(jq -r '(.spare_thresh // .available_spare_threshold // 0) | tonumber? // 0' <<< "$smart_json")"
            percentage_used="$(jq -r '(.percent_used // .percentage_used // 0) | tonumber? // 0' <<< "$smart_json")"
            temperature="$(jq -r '(.temperature // 0) | tonumber? // 0' <<< "$smart_json")"
            unsafe_shutdowns="$(jq -r '(.unsafe_shutdowns // 0) | tonumber? // 0' <<< "$smart_json")"
            media_errors="$(jq -r '(.media_errors // 0) | tonumber? // 0' <<< "$smart_json")"
            error_entries="$(jq -r '(.num_err_log_entries // 0) | tonumber? // 0' <<< "$smart_json")"

            ((critical_warning == 0)) || add_issue "$device has NVMe critical warning $critical_warning"
            ((available_spare >= spare_threshold)) || add_issue "$device available spare is below threshold"
            ((percentage_used < 90)) || add_issue "$device reports ''${percentage_used}% lifetime used"
            ((temperature < 353)) || add_issue "$device temperature is at least 80°C"
            ((media_errors == 0)) || add_issue "$device reports media or data-integrity errors"
            ((error_entries == 0)) || add_issue "$device NVMe error log contains entries"

            if jq -e --arg device "$device_name" 'has($device)' <<< "$previous_counters" >/dev/null; then
              previous_unsafe="$(jq -r --arg device "$device_name" '.[$device].unsafe_shutdowns // 0' <<< "$previous_counters")"
              if ((unsafe_shutdowns > previous_unsafe)); then
                add_issue "$device recorded a new unsafe shutdown"
              fi
            fi

            current_counters="$(
              jq \
                --arg device "$device_name" \
                --argjson unsafe "$unsafe_shutdowns" \
                --argjson media "$media_errors" \
                --argjson errors "$error_entries" \
                '.[$device] = {
                  unsafe_shutdowns: $unsafe,
                  media_errors: $media,
                  error_entries: $errors
                }' <<< "$current_counters"
            )"

            printf '\n== %s error log ==\n' "$device"
            nvme error-log "$device" || add_issue "Unable to read $device error log"
            printf '\n== %s self-test log ==\n' "$device"
            nvme self-test-log "$device" || add_issue "Unable to read $device self-test log"
          done
        } > "$temporary_report" 2>&1

        printf '%s\n' "$current_counters" > "$temporary_counters"
        chmod 0644 "$temporary_counters" "$temporary_report"
        mv "$temporary_counters" "$counters_file"
        mv "$temporary_report" "$report_file"

        issues_json="$(printf '%s\0' "''${issues[@]}" | jq -Rs 'split("\u0000") | map(select(length > 0))')"
        if ((''${#issues[@]} > 0)); then
          issue_id="$(printf '%s\n' "''${issues[@]}" | sha256sum | cut -d ' ' -f 1)"
          summary="''${#issues[@]} storage health warning(s)"
          state=warning
        else
          issue_id=""
          summary="Storage is healthy"
          state=ok
        fi

        jq -n \
          --arg state "$state" \
          --arg id "$issue_id" \
          --arg summary "$summary" \
          --arg checked_at "$(date --iso-8601=seconds)" \
          --arg report "$report_file" \
          --argjson issues "$issues_json" \
          '{
            state: $state,
            id: $id,
            summary: $summary,
            checked_at: $checked_at,
            report: $report,
            issues: $issues
          }' > "$temporary_status"
        chmod 0644 "$temporary_status"
        mv "$temporary_status" "$status_file"
      '';
    };
  in {
    environment.systemPackages = [
      pkgs.nvme-cli
      pkgs.smartmontools
      storageHealthCheck
    ];

    systemd = {
      services.nixconf-storage-health = {
        description = "Check Btrfs and NVMe health";
        after = ["local-fs.target"];
        requires = ["local-fs.target"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${storageHealthCheck}/bin/nixconf-storage-health-check";
          StateDirectory = "nixconf-storage-health";
          StateDirectoryMode = "0755";
        };
      };

      timers.nixconf-storage-health = {
        description = "Check Btrfs and NVMe health daily";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };
    };
  };
}
