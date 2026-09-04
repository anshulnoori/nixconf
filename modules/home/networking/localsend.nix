{inputs, ...}: {
  flake.modules.homeManager.desktop = {
    lib,
    pkgs,
    ...
  }: let
    configureLocalSend = pkgs.writeShellApplication {
      name = "nixconf-configure-localsend";
      runtimeInputs = with pkgs; [
        coreutils
        jq
        libnotify
        tailscale
      ];
      text = ''
        mapfile -t addresses < <(
          tailscale ip -4 2>/dev/null || true
          tailscale ip -6 2>/dev/null || true
        )

        if ((''${#addresses[@]} == 0)); then
          notify-send \
            --app-name=nixconf-localsend \
            --urgency=critical \
            "LocalSend requires Tailscale" \
            "Connect Tailscale before opening LocalSend."
          exit 1
        fi

        data_home="''${XDG_DATA_HOME:-$HOME/.local/share}"
        current_dir="$data_home/org.localsend.localsend_app"
        legacy_dir="$data_home/localsend_app"
        if [[ -d "$legacy_dir" && ! -d "$current_dir" ]]; then
          preferences="$legacy_dir/shared_preferences.json"
        else
          preferences="$current_dir/shared_preferences.json"
        fi

        existing='{}'
        if [[ -f "$preferences" ]]; then
          if ! jq -e 'type == "object"' "$preferences" >/dev/null; then
            notify-send \
              --app-name=nixconf-localsend \
              --urgency=critical \
              "LocalSend settings are invalid" \
              "Refusing to overwrite $preferences."
            exit 1
          fi
          existing="$(< "$preferences")"
        elif [[ -e "$preferences" ]]; then
          notify-send \
            --app-name=nixconf-localsend \
            --urgency=critical \
            "LocalSend settings are unavailable" \
            "$preferences is not a regular file."
          exit 1
        fi

        whitelist="$(printf '%s\n' "''${addresses[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')"
        directory="$(dirname "$preferences")"
        mkdir -p "$directory"
        temporary="$(mktemp "$directory/.shared_preferences.json.XXXXXX")"
        trap 'rm -f "$temporary"' EXIT

        jq -n \
          --argjson existing "$existing" \
          --argjson whitelist "$whitelist" \
          '$existing
            + {"flutter.ls_network_whitelist": $whitelist}
            | del(."flutter.ls_network_blacklist")' \
          > "$temporary"
        chmod 0600 "$temporary"
        mv -f "$temporary" "$preferences"
        trap - EXIT
      '';
    };
    localsendTailscale = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.localsend;
      preHook = lib.getExe configureLocalSend;
    };
  in {
    home.packages = [localsendTailscale];
  };
}
