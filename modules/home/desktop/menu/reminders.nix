_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    reminders = pkgs.writeShellApplication {
      name = "nixconf-reminder";
      runtimeInputs = with pkgs; [
        todoist-electron
        util-linux
        uwsm
        xdg-utils
      ];
      text = ''
        case "''${1:-}" in
          add) target='todoist://openquickadd' ;;
          upcoming) target='https://app.todoist.com/app/upcoming' ;;
          open) target='todoist://' ;;
          *)
            printf 'Usage: nixconf-reminder <add|upcoming|open>\n' >&2
            exit 2
            ;;
        esac

        exec setsid uwsm app -- xdg-open "$target"
      '';
    };
  in {
    home.packages = [
      pkgs.todoist-electron
      reminders
    ];
  };
}
