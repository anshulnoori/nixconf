_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    captureQr = pkgs.writeShellApplication {
      name = "capture-qr";
      runtimeInputs = with pkgs; [
        coreutils
        grim
        hyprpicker
        libnotify
        slurp
        wl-clipboard
        zbar
      ];
      text = ''
        hyprpicker -r -z >/dev/null 2>&1 &
        freeze_pid=$!
        trap 'kill "$freeze_pid" 2>/dev/null || true' EXIT
        sleep 0.1
        selection="$(slurp 2>/dev/null || true)"
        [[ -n "$selection" ]] || exit 0

        value="$(grim -g "$selection" - | zbarimg --quiet --raw - 2>/dev/null | head -n 1)"
        if [[ -z "$value" ]]; then
          notify-send --app-name=nixconf-capture "No QR code found"
          exit 1
        fi

        printf '%s' "$value" | wl-copy
        notify-send --app-name=nixconf-capture "QR code copied" "$value"
      '';
    };
  in {
    home.packages = [captureQr];
  };
}
