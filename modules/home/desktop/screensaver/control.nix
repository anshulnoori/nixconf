_: {
  flake.modules.homeManager.desktop = {
    config,
    osConfig,
    pkgs,
    ...
  }: let
    runner = import ./_runner.nix {
      inherit osConfig pkgs;
      colors = config.lib.stylix.colors;
    };
    control = pkgs.writeShellApplication {
      name = "nixconf-screensaver";
      runtimeInputs = with pkgs; [
        coreutils
        jq
        kitty
        libnotify
        osConfig.programs.hyprland.package
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
                ${runner}/bin/nixconf-screensaver-run \
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
    home.packages = [control];

    wayland.windowManager.hyprland.extraConfig = ''
      hl.window_rule({
        match = { class = "org.nixconf.screensaver" },
        fullscreen = true,
        float = true,
      })
    '';
  };
}
