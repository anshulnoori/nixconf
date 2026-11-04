_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    focusAndOpen = pkgs.writeShellApplication {
      name = "focus-and-open";
      runtimeInputs = [pkgs.jq];
      text = ''
        class=$1
        shift
        address=$(hyprctl clients -j | jq -r --arg class "$class" '[.[] | select(.class == $class)] | min_by(.focusHistoryID) | .address // empty')
        if [[ -n "$address" ]]; then
          hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null
        fi
        exec "$@"
      '';
    };
    linkHandler = name: class: command: mimeType: {
      inherit name mimeType;
      exec = "${pkgs.lib.getExe focusAndOpen} ${class} ${command} %U";
      noDisplay = true;
      terminal = false;
    };
  in {
    xdg.desktopEntries = {
      brave-origin-link = linkHandler "Brave Origin" "brave-origin" "brave-origin" [
        "text/html"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      amp-desktop-link = linkHandler "Amp" "amp-desktop" "amp-desktop" [
        "x-scheme-handler/com.ampcode.amp.linux.auth"
      ];
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = ["brave-origin-link.desktop"];
        "x-scheme-handler/http" = ["brave-origin-link.desktop"];
        "x-scheme-handler/https" = ["brave-origin-link.desktop"];
        "x-scheme-handler/com.ampcode.amp.linux.auth" = ["amp-desktop-link.desktop"];
      };
    };
  };
}
