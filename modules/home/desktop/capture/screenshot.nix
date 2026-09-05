_: {
  flake.modules.homeManager.desktop = {
    config,
    pkgs,
    ...
  }: let
    captureScreenshot = pkgs.writeShellApplication {
      name = "capture-screenshot";
      runtimeInputs = with pkgs; [
        config.nixconf.desktop.capture.regionPicker
        coreutils
        grim
        libnotify
        procps
        satty
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

        mode="''${1:-smart}"
        case "$mode" in
          region | windows | smart | fullscreen) ;;
          *)
            printf 'Usage: capture-screenshot <region|windows|smart|fullscreen>\n' >&2
            exit 2
            ;;
        esac

        pick=()
        mapfile -t pick < <(capture-region-pick "$mode" --keep-freeze || true)
        freeze_pid="''${pick[0]:-}"
        selection="''${pick[1]:-}"
        [[ -n "$selection" ]] || exit 0

        file="$(mktemp "$output_dir/screenshot-$(date +'%Y-%m-%d_%H-%M-%S')-XXXXXX.png")"
        if ! grim -g "$selection" "$file"; then
          rm -f "$file"
          exit 1
        fi
        cleanup_freeze
        freeze_pid=
        trap - EXIT
        wl-copy --type image/png < "$file"

        (
          action="$(notify-send \
            --app-name=nixconf-capture \
            "Screenshot saved" \
            "Copied to clipboard • Click to edit" \
            --icon="$file" \
            --expire-time=10000 \
            --action="default=Edit" || true)"

          if [[ "$action" == "default" ]]; then
            satty \
              --filename "$file" \
              --output-filename "$file" \
              --actions-on-enter save-to-clipboard \
              --save-after-copy \
              --copy-command 'wl-copy --type image/png'
          fi
        ) >/dev/null 2>&1 &
      '';
    };
  in {
    home.packages = [captureScreenshot];
  };
}
