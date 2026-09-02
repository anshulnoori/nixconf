_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    hardwareActions = pkgs.writeShellApplication {
      name = "nixconf-hardware";
      runtimeInputs = with pkgs; [
        coreutils
        gnugrep
        hyprland
        jq
        libnotify
        pciutils
      ];
      text = ''
        runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}"

        notify() {
          notify-send --app-name=nixconf-menu "$1" "''${2:-}"
        }

        internal_display() {
          hyprctl monitors all -j | jq -r '[.[] | select(.name | test("^eDP"))][0].name // empty'
        }

        external_display() {
          hyprctl monitors all -j | jq -r '[.[] | select(.name | test("^eDP") | not)][0].name // empty'
        }

        touchpad_device() {
          hyprctl devices -j | jq -r '[.mice[] | .name | select(test("touchpad|trackpad"; "i"))][0] // empty'
        }

        touchscreen_device() {
          hyprctl devices -j | jq -r '[.touch[]?.name, .tablets[]?.name][0] // empty'
        }

        available() {
          case "$1" in
            laptop-display) [[ -n "$(internal_display)" ]] ;;
            mirror-display) [[ -n "$(internal_display)" && -n "$(external_display)" ]] ;;
            hybrid-gpu)
              gpu_count="$(lspci | grep -Ec 'VGA|3D|Display' || true)"
              (( gpu_count >= 2 ))
              ;;
            touchpad) [[ -n "$(touchpad_device)" ]] ;;
            touchpad-haptics)
              [[ -e /sys/bus/i2c/devices/i2c-VEN_06CB:00 ]] &&
                command -v dell-xps-touchpad-haptics >/dev/null
              ;;
            touchscreen) [[ -n "$(touchscreen_device)" ]] ;;
            *) return 1 ;;
          esac
        }

        toggle_laptop_display() {
          internal="$(internal_display)"
          [[ -n "$internal" ]] || exit 1

          if hyprctl monitors -j | jq -e --arg name "$internal" '.[] | select(.name == $name)' >/dev/null; then
            external_count="$(hyprctl monitors -j | jq --arg name "$internal" '[.[] | select(.name != $name)] | length')"
            if (( external_count == 0 )); then
              notify "Laptop display unchanged" "It is the only active display"
              exit 1
            fi
            hyprctl keyword monitor "$internal,disable" >/dev/null
            notify "Laptop display disabled"
          else
            hyprctl keyword monitor "$internal,preferred,auto,auto" >/dev/null
            notify "Laptop display enabled"
          fi
        }

        toggle_mirror_display() {
          internal="$(internal_display)"
          external="$(external_display)"
          [[ -n "$internal" && -n "$external" ]] || exit 1
          flag="$runtime_dir/nixconf-display-mirrored"

          if [[ -e "$flag" ]]; then
            hyprctl keyword monitor "$external,preferred,auto,auto" >/dev/null
            rm -f "$flag"
            notify "Display mirroring disabled"
          else
            hyprctl keyword monitor "$internal,preferred,auto,auto" >/dev/null
            hyprctl keyword monitor "$external,preferred,auto,1,mirror,$internal" >/dev/null
            touch "$flag"
            notify "Display mirroring enabled" "$external mirrors $internal"
          fi
        }

        toggle_device() {
          kind="$1"
          case "$kind" in
            touchpad) device="$(touchpad_device)" ;;
            touchscreen) device="$(touchscreen_device)" ;;
            *) exit 2 ;;
          esac
          [[ -n "$device" ]] || exit 1

          flag="$runtime_dir/nixconf-$kind-disabled"
          quoted_device="$(jq -Rn --arg device "$device" '$device')"
          if [[ -e "$flag" ]]; then
            hyprctl eval "hl.device({ name = $quoted_device, enabled = true })" >/dev/null
            rm -f "$flag"
            notify "''${kind^} enabled"
          else
            hyprctl eval "hl.device({ name = $quoted_device, enabled = false })" >/dev/null
            touch "$flag"
            notify "''${kind^} disabled"
          fi
        }

        case "''${1:-}" in
          available) available "''${2:-}" ;;
          laptop-display) toggle_laptop_display ;;
          mirror-display) toggle_mirror_display ;;
          touchpad | touchscreen) toggle_device "$1" ;;
          touchpad-haptics)
            level="''${2:-}"
            case "$level" in low | mid | high) ;; *) exit 2 ;; esac
            dell-xps-touchpad-haptics set "$level"
            notify "Touchpad haptics" "''${level^}"
            ;;
          *)
            printf 'Usage: nixconf-hardware <available|laptop-display|mirror-display|touchpad|touchpad-haptics|touchscreen>\n' >&2
            exit 2
            ;;
        esac
      '';
    };
  in {
    home.packages = [hardwareActions];
  };
}
