_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    captureScreenshot = pkgs.writeShellApplication {
      name = "capture-screenshot";
      runtimeInputs = with pkgs; [
        coreutils
        grim
        hyprpicker
        libnotify
        procps
        satty
        slurp
        wl-clipboard
      ];
      text = ''
        output_dir="$HOME/Pictures/Screenshots"
        mkdir -p "$output_dir"

        pkill slurp 2>/dev/null && exit 0

        hyprpicker -r -z >/dev/null 2>&1 &
        freeze_pid=$!
        trap 'kill "$freeze_pid" 2>/dev/null || true' EXIT
        sleep 0.1

        selection="$(slurp 2>/dev/null || true)"
        [[ -n "$selection" ]] || exit 0

        file="$output_dir/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"
        grim -g "$selection" "$file"
        kill "$freeze_pid" 2>/dev/null || true
        trap - EXIT
        wl-copy < "$file"

        action="$(notify-send \
          "Screenshot saved" \
          "Copied to clipboard" \
          --icon="$file" \
          --expire-time=10000 \
          --action="default=Edit" || true)"

        if [[ "$action" == "default" ]]; then
          satty \
            --filename "$file" \
            --output-filename "$file" \
            --actions-on-enter save-to-clipboard \
            --save-after-copy \
            --copy-command wl-copy
        fi
      '';
    };
  in {
    home.packages = [captureScreenshot];
  };
}
