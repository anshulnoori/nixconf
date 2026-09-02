_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    systemActions = pkgs.writeShellApplication {
      name = "nixconf-system";
      runtimeInputs = with pkgs; [
        gnugrep
        nh
        systemd
      ];
      text = ''
        case "''${1:-}" in
          available)
            case "''${2:-}" in
              hibernate)
                busctl call \
                  org.freedesktop.login1 \
                  /org/freedesktop/login1 \
                  org.freedesktop.login1.Manager \
                  CanHibernate 2>/dev/null | grep -Eq '"(yes|challenge)"'
                ;;
              *) exit 1 ;;
            esac
            ;;
          nix)
            operation="''${2:-}"
            case "$operation" in
              build | test | switch | boot)
                exec present-terminal "NixOS ''${operation^}" \
                  nh os "$operation" /etc/nixos
                ;;
              update)
                exec present-terminal "NixOS Update" \
                  nh os switch --update /etc/nixos
                ;;
              clean)
                exec present-terminal "Nix Store Cleanup" \
                  nh clean all --keep 6 --keep-one --ask
                ;;
              *)
                printf 'Usage: nixconf-system nix <build|test|switch|boot|update|clean>\n' >&2
                exit 2
                ;;
            esac
            ;;
          *)
            printf 'Usage: nixconf-system <available|nix> ...\n' >&2
            exit 2
            ;;
        esac
      '';
    };
  in {
    home.packages = [systemActions];
  };
}
