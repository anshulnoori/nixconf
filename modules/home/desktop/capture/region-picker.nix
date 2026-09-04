_: {
  flake.modules.homeManager.desktop = {
    lib,
    osConfig,
    pkgs,
    ...
  }: let
    regionPicker = pkgs.writeShellApplication {
      name = "capture-region-pick";
      runtimeInputs = with pkgs; [
        coreutils
        hyprpicker
        jq
        osConfig.programs.hyprland.package
        slurp
      ];
      text = ''
        mode=smart
        keep_freeze=false
        match_monitor=false

        for argument in "$@"; do
          case "$argument" in
            region | windows | smart | fullscreen) mode="$argument" ;;
            --keep-freeze) keep_freeze=true ;;
            --match-monitor) match_monitor=true ;;
            *)
              printf 'Usage: capture-region-pick [region|windows|smart|fullscreen] [--keep-freeze] [--match-monitor]\n' >&2
              exit 2
              ;;
          esac
        done

        get_rectangles() {
          local active_workspace

          active_workspace="$(hyprctl monitors -j | jq -r '.[] | select(.focused).activeWorkspace.id')"
          hyprctl monitors -j | jq -r --arg workspace "$active_workspace" '
            .[] | select(.activeWorkspace.id == ($workspace | tonumber)) |
            .x as $x | .y as $y |
            (.width / .scale | floor) as $w |
            (.height / .scale | floor) as $h |
            if .transform % 2 == 1 then
              "\($x),\($y) \($h)x\($w)"
            else
              "\($x),\($y) \($w)x\($h)"
            end
          '
          hyprctl clients -j | jq -r --arg workspace "$active_workspace" '
            .[] | select(.workspace.id == ($workspace | tonumber)) |
            "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"
          '
        }

        freeze_pid=
        cleanup_freeze() {
          if [[ "$keep_freeze" != true && -n "$freeze_pid" ]]; then
            kill "$freeze_pid" 2>/dev/null || true
          fi
        }
        trap cleanup_freeze EXIT

        freeze_screen() {
          hyprpicker -r -z >/dev/null 2>&1 &
          freeze_pid=$!
          sleep 0.1
        }

        selection=
        case "$mode" in
          region)
            freeze_screen
            selection="$(slurp 2>/dev/null || true)"
            ;;
          windows)
            freeze_screen
            selection="$(get_rectangles | slurp -r 2>/dev/null || true)"
            ;;
          fullscreen)
            selection="$(hyprctl monitors -j | jq -r '
              .[] | select(.focused) |
              .x as $x | .y as $y |
              (.width / .scale | floor) as $w |
              (.height / .scale | floor) as $h |
              if .transform % 2 == 1 then
                "\($x),\($y) \($h)x\($w)"
              else
                "\($x),\($y) \($w)x\($h)"
              end
            ')"
            ;;
          smart)
            rectangles="$(get_rectangles)"
            freeze_screen
            selection="$(printf '%s\n' "$rectangles" | slurp 2>/dev/null || true)"

            if [[ "$selection" =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]] &&
              ((BASH_REMATCH[3] * BASH_REMATCH[4] < 20)); then
              click_x="''${BASH_REMATCH[1]}"
              click_y="''${BASH_REMATCH[2]}"

              while IFS= read -r rectangle; do
                [[ "$rectangle" =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]] || continue
                rectangle_x="''${BASH_REMATCH[1]}"
                rectangle_y="''${BASH_REMATCH[2]}"
                rectangle_width="''${BASH_REMATCH[3]}"
                rectangle_height="''${BASH_REMATCH[4]}"

                if ((
                  click_x >= rectangle_x &&
                  click_x < rectangle_x + rectangle_width &&
                  click_y >= rectangle_y &&
                  click_y < rectangle_y + rectangle_height
                )); then
                  selection="$rectangle_x,$rectangle_y ''${rectangle_width}x$rectangle_height"
                  break
                fi
              done <<< "$rectangles"
            fi
            ;;
        esac

        if [[ "$keep_freeze" == true ]]; then
          printf '%s\n' "$freeze_pid"
        fi

        [[ -n "$selection" ]] || exit 1

        if [[ "$match_monitor" == true ]]; then
          monitor="$(hyprctl monitors -j | jq -r \
            --arg geometry "$selection" '
              .[] |
              .x as $x | .y as $y |
              (.width / .scale | floor) as $w |
              (.height / .scale | floor) as $h |
              (if .transform % 2 == 1 then
                "\($x),\($y) \($h)x\($w)"
              else
                "\($x),\($y) \($w)x\($h)"
              end) as $monitor_geometry |
              select($monitor_geometry == $geometry) |
              .name
            ' | head -n 1)"

          if [[ -n "$monitor" ]]; then
            printf 'monitor:%s\n' "$monitor"
            exit 0
          fi
        fi

        printf '%s\n' "$selection"
      '';
    };
  in {
    options.nixconf.desktop.capture.regionPicker = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
    };

    config.nixconf.desktop.capture.regionPicker = regionPicker;
  };
}
