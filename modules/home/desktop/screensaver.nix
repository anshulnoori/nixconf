_: {
  flake.modules.homeManager.desktop = {
    config,
    osConfig,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
    artwork = pkgs.writeText "nixos-screensaver.txt" ''
                ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖
                ▜███▙       ▜███▙  ▟███▛
                 ▜███▙       ▜███▙▟███▛
                  ▜███▙       ▜██████▛
           ▟█████████████████▙ ▜████▛     ▟▙
          ▟███████████████████▙ ▜███▙    ▟██▙
                 ▄▄▄▄▖           ▜███▙  ▟███▛
                ▟███▛             ▜██▛ ▟███▛
               ▟███▛               ▜▛ ▟███▛
      ▟███████████▛                  ▟██████████▙
      ▜██████████▛                  ▟███████████▛
            ▟███▛ ▟▙               ▟███▛
           ▟███▛ ▟██▙             ▟███▛
          ▟███▛  ▜███▙           ▝▀▀▀▀
          ▜██▛    ▜███▙ ▜██████████████████▛
           ▜▛     ▟████▙ ▜████████████████▛
                 ▟██████▙         ▜███▙
                ▟███▛▜███▙         ▜███▙
               ▟███▛  ▜███▙         ▜███▙
               ▝▀▀▀    ▀▀▀▀▘         ▀▀▀▘
    '';
    runner = pkgs.writeShellApplication {
      name = "nixconf-screensaver-run";
      runtimeInputs = with pkgs; [
        coreutils
        jq
        osConfig.programs.hyprland.package
        systemd
        terminaltexteffects
      ];
      text = ''
        effect_pid=

        screensaver_in_focus() {
          hyprctl activewindow -j | jq -e '.class == "org.nixconf.screensaver"' >/dev/null 2>&1
        }

        screensaver_present() {
          hyprctl clients -j | jq -e 'any(.[]; .class == "org.nixconf.screensaver")' >/dev/null 2>&1
        }

        exit_screensaver() {
          systemctl --user --no-block stop nixconf-screensaver.service
          exit 0
        }

        trap 'exit 0' INT TERM HUP QUIT
        printf '\033]11;#${colors.base00}\007'

        for _ in {1..30}; do
          screensaver_present && break
          sleep 0.1
        done
        screensaver_present || exit 1
        sleep 0.4

        while true; do
          tte -i ${artwork} \
            --frame-rate 120 \
            --canvas-width 0 \
            --canvas-height 0 \
            --reuse-canvas \
            --anchor-canvas c \
            --anchor-text c \
            --random-effect \
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
    session = pkgs.writeShellApplication {
      name = "nixconf-screensaver-session";
      runtimeInputs = with pkgs; [coreutils jq kitty osConfig.programs.hyprland.package walker];
      text = ''
        walker -q >/dev/null 2>&1 || true
        focused="$(hyprctl monitors -j | jq -r '.[] | select(.focused).name')"
        mapfile -t monitors < <(hyprctl monitors -j | jq -r '.[].name')
        (( ''${#monitors[@]} > 0 )) || exit 1
        hyprctl eval 'hl.config({ cursor = { invisible = true } })' >/dev/null
        windows=()
        for monitor in "''${monitors[@]}"; do
          hyprctl dispatch "hl.dsp.focus({ monitor = \"$monitor\" })" >/dev/null
          kitty --class org.nixconf.screensaver \
            --override font_size=12 \
            --override window_padding_width=0 \
            ${runner}/bin/nixconf-screensaver-run &
          windows+=("$!")
          for _ in {1..30}; do
            if hyprctl clients -j | jq -e \
              --argjson id "$(hyprctl monitors -j | jq --arg name "$monitor" '.[] | select(.name == $name).id')" \
              'any(.[]; .class == "org.nixconf.screensaver" and .monitor == $id)' >/dev/null; then
              break
            fi
            sleep 0.1
          done
        done
        [[ -z "$focused" ]] || hyprctl dispatch "hl.dsp.focus({ monitor = \"$focused\" })" >/dev/null
        wait -n "''${windows[@]}"
      '';
    };
    control = pkgs.writeShellApplication {
      name = "nixconf-screensaver";
      runtimeInputs = with pkgs; [
        coreutils
        libnotify
        systemd
      ];
      text = ''
        state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/nixconf"
        disabled_file="$state_dir/screensaver-disabled"

        mkdir -p "$state_dir"

        stop_screensaver() {
          systemctl --user stop nixconf-screensaver.service
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

            systemctl --user start nixconf-screensaver.service
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

    systemd.user.services.nixconf-screensaver = {
      Unit = {
        Description = "Desktop screensaver";
        After = ["graphical-session.target"];
        BindsTo = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Type = "exec";
        ExecStart = "${session}/bin/nixconf-screensaver-session";
        ExecStopPost = "-${osConfig.programs.hyprland.package}/bin/hyprctl eval 'hl.config({ cursor = { invisible = false } })'";
        TimeoutStopSec = 5;
      };
    };

    wayland.windowManager.hyprland.settings.window_rule = [
      {
        match.class = "org.nixconf.screensaver";
        fullscreen = true;
        float = true;
      }
    ];
  };
}
