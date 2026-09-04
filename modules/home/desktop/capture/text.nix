_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    captureText = pkgs.writeShellApplication {
      name = "capture-text";
      runtimeInputs = with pkgs; [
        coreutils
        grim
        hyprpicker
        libnotify
        slurp
        tesseract5
        wl-clipboard
      ];
      text = ''
        hyprpicker -r -z >/dev/null 2>&1 &
        freeze_pid=$!
        trap 'kill "$freeze_pid" 2>/dev/null || true' EXIT
        sleep 0.1
        selection="$(slurp 2>/dev/null || true)"
        [[ -n "$selection" ]] || exit 0

        text="$(grim -g "$selection" - | tesseract stdin stdout \
          --oem 1 \
          --psm 6 \
          -l eng \
          --dpi 300 \
          -c preserve_interword_spaces=1 \
          2>/dev/null)"
        [[ -n "$text" ]] || exit 1

        printf '%s' "$text" | wl-copy
        notify-send --app-name=nixconf-capture "Text copied"
      '';
    };
  in {
    home.packages = [captureText];
  };
}
