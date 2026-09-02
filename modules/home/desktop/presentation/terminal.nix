_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    terminalPresentation = pkgs.writeShellApplication {
      name = "terminal-presentation";
      runtimeInputs = [
        pkgs.gum
        pkgs.ncurses
      ];
      text = ''
        clear
        status=0
        "$@" || status=$?

        if (( status != 130 )); then
          printf '\n'
          gum spin --spinner globe --title "Done! Press any key to close..." -- \
            ${pkgs.bash}/bin/bash -c "read -n 1 -s"
        fi

        exit "$status"
      '';
    };
    presentTerminal = pkgs.writeShellApplication {
      name = "present-terminal";
      runtimeInputs = [
        pkgs.kitty
        pkgs.util-linux
        pkgs.uwsm
      ];
      text = ''
        if (( $# < 2 )); then
          printf 'Usage: present-terminal <title> <command> [args...]\n' >&2
          exit 2
        fi

        title="$1"
        shift

        exec setsid uwsm app -- kitty --class TUI.float --title "$title" \
          ${terminalPresentation}/bin/terminal-presentation "$@"
      '';
    };
  in {
    home.packages = [presentTerminal];

    wayland.windowManager.hyprland.extraConfig = ''
      hl.window_rule({
        match = { class = "TUI.float" },
        float = true,
        center = 1,
        size = { 875, 600 },
      })
    '';
  };
}
