_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    captureColor = pkgs.writeShellApplication {
      name = "capture-color";
      runtimeInputs = with pkgs; [
        hyprpicker
        libnotify
        procps
        wl-clipboard
      ];
      text = ''
        if pkill -x hyprpicker 2>/dev/null; then
          exit 0
        fi

        color="$(hyprpicker)"
        [[ -n "$color" ]] || exit 0
        printf '%s' "$color" | wl-copy
        notify-send --app-name=nixconf-capture "Color copied" "$color"
      '';
    };
  in {
    home.packages = [captureColor];
  };
}
