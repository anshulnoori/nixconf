{inputs, ...}: {
  flake.modules.homeManager.desktop = {
    config,
    lib,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
    source = "${inputs.omarchy-rice}/themes/flexoki-light/backgrounds/1-orb.png";
    wallpaper = pkgs.runCommand "flexoki-orb-gruvbox.png" {nativeBuildInputs = [pkgs.imagemagick];} ''
      magick ${source} -colorspace gray -negate \
        +level-colors '#${colors.base00}','#${colors.base05}' "$out"
    '';
    wallpaperState = "${config.xdg.stateHome}/nixconf/wallpaper";
    wallpaperRunner = pkgs.writeShellApplication {
      name = "nixconf-wallpaper-run";
      runtimeInputs = [pkgs.swaybg];
      text = ''
        selected=${lib.escapeShellArg wallpaperState}
        if [[ ! -r "$selected" ]]; then
          selected=${lib.escapeShellArg (toString wallpaper)}
        fi

        exec swaybg -i "$selected" -m fill
      '';
    };
    wallpaperControl = pkgs.writeShellApplication {
      name = "nixconf-wallpaper";
      runtimeInputs = with pkgs; [
        coreutils
        findutils
        libnotify
        systemd
      ];
      text = ''
        state=${lib.escapeShellArg wallpaperState}

        case "''${1:-}" in
          list)
            for directory in \
              "''${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers" \
              "$HOME/Pictures/Wallpapers"; do
              [[ -d "$directory" ]] || continue
              find -L "$directory" -type f \
                \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
                -printf '%p\t%f\n'
            done | sort -t $'\t' -k2,2 -u
            ;;
          set)
            selected="''${2:-}"
            if [[ -z "$selected" ]]; then
              IFS= read -r selected || [[ -n "$selected" ]]
            fi

            if [[ ! -f "$selected" ]]; then
              notify-send --app-name=nixconf-menu "Background unavailable" "$selected"
              exit 1
            fi

            mkdir -p "$(dirname "$state")"
            temporary="$state.new"
            ln -sfn "$(realpath "$selected")" "$temporary"
            mv -Tf "$temporary" "$state"
            systemctl --user restart swaybg.service
            notify-send --app-name=nixconf-menu "Background changed" "$(basename "$selected")"
            ;;
          *)
            printf 'Usage: nixconf-wallpaper <list|set> [path]\n' >&2
            exit 2
            ;;
        esac
      '';
    };
  in {
    options.nixconf.desktop.wallpaper = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
    };

    config = {
      nixconf.desktop.wallpaper = wallpaper;
      xdg.dataFile."wallpapers/gruvbox/flexoki-orb.png".source = config.nixconf.desktop.wallpaper;
      home.packages = [wallpaperControl];

      home.activation.initializeWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p ${lib.escapeShellArg (builtins.dirOf wallpaperState)}
        if [[ ! -e ${lib.escapeShellArg wallpaperState} && ! -L ${lib.escapeShellArg wallpaperState} ]]; then
          $DRY_RUN_CMD ln -s ${lib.escapeShellArg (toString wallpaper)} ${lib.escapeShellArg wallpaperState}
        fi
      '';

      systemd.user.services.swaybg = {
        Unit = {
          Description = "Gruvbox Flexoki Orb desktop wallpaper";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          ExecStart = "${wallpaperRunner}/bin/nixconf-wallpaper-run";
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = ["graphical-session.target"];
      };
    };
  };
}
