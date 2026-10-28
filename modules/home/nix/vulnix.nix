_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    scan = pkgs.writeShellApplication {
      name = "nixconf-vulnix-scan";
      runtimeInputs = with pkgs; [
        coreutils
        jq
        libnotify
        vulnix
      ];
      text = ''
        state="''${XDG_STATE_HOME:-$HOME/.local/state}/vulnix"
        mkdir -p "$state"

        # Scan the runtime closure only; build-time inputs are not installed.
        status=0
        vulnix --closure /run/current-system --json \
          --whitelist ${./vulnix-whitelist.toml} > "$state/scan.json" || status=$?
        if [[ $status -gt 2 ]]; then
          notify-send --app-name=vulnix "Vulnerability scan failed" \
            "journalctl --user -u nixconf-vulnix"
          exit "$status"
        fi

        # TeX Live package names collide with unrelated products in NVD.
        jq '[.[] | select(.version | endswith("-tex") | not)
                 | {name, pname, cves: .affected_by, score: ([.cvssv3_basescore[]?] | max)}]
            | sort_by(-(.score // 0))' "$state/scan.json" > "$state/findings.json.new"

        jq -r '.[] | "\(.score // "-")\t\(.name)\t\(.cves | join(" "))"' \
          "$state/findings.json.new" | tee "$state/report.txt"

        # Notify only about CVEs that the previous scan did not report.
        [[ -f $state/findings.json ]] || echo '[]' > "$state/findings.json"
        new="$(jq --slurpfile old "$state/findings.json" \
          '[.[] | .pname as $n | .cves[] | "\($n) \(.)"]
           - [$old[0][] | .pname as $n | .cves[] | "\($n) \(.)"] | unique | length' \
          "$state/findings.json.new")"
        mv "$state/findings.json.new" "$state/findings.json"

        if [[ $new -gt 0 ]]; then
          notify-send --app-name=vulnix \
            "$new new vulnerabilities in the current system" \
            "$(jq length "$state/findings.json") packages affected. Report: $state/report.txt"
        fi
      '';
    };
  in {
    home.packages = [pkgs.vulnix];

    systemd.user = {
      services.nixconf-vulnix = {
        Unit.Description = "Scan the current system for known vulnerabilities";
        Service = {
          Type = "oneshot";
          ExecStart = "${scan}/bin/nixconf-vulnix-scan";
          Nice = 19;
          IOSchedulingClass = "idle";
        };
      };
      timers.nixconf-vulnix = {
        Unit.Description = "Daily vulnerability scan of the current system";
        Timer = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
        Install.WantedBy = ["timers.target"];
      };
    };
  };
}
