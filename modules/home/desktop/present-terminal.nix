_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    terminalRunner = pkgs.writeShellApplication {
      name = "terminal-presentation";
      runtimeInputs = [pkgs.ncurses];
      text = ''
        clear
        status=0
        "$@" || status=$?

        if (( status != 130 )) && : 2>/dev/null <>/dev/tty; then
          while read -r -s -n 1 -t 0.1 _ </dev/tty; do :; done
          printf '\nDone! Press any key to close...' >/dev/tty
          read -r -s -n 1 </dev/tty
          printf '\n' >/dev/tty
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
        runner=(${terminalRunner}/bin/terminal-presentation)
        if [[ "''${1-}" == --close-on-exit ]]; then
          runner=()
          shift
        fi

          if (( $# < 2 )); then
            printf 'Usage: present-terminal [--close-on-exit] <title> <command> [args...]\n' >&2
            exit 2
          fi

          title="$1"
          shift

          exec setsid uwsm app -- kitty --class TUI.float --title "$title" \
            --override remember_window_size=no \
            "''${runner[@]}" "$@"
      '';
    };
  in {
    home.packages = [presentTerminal];

    wayland.windowManager.hyprland.settings.window_rule = [
      {
        match.class = "TUI.float";
        float = true;
        center = 1;
        size = [875 600];
      }
    ];
  };
}
