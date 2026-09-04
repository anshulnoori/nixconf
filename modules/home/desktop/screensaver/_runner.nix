{
  colors,
  osConfig,
  pkgs,
}:
pkgs.writeShellApplication {
  name = "nixconf-screensaver-run";
  runtimeInputs = with pkgs; [
    coreutils
    jq
    osConfig.programs.hyprland.package
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
    printf '\033]11;#${colors.base00}\007'
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
}
