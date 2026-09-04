_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    configEditor = pkgs.writeShellApplication {
      name = "nixconf-edit";
      runtimeInputs = with pkgs; [
        coreutils
        direnv
        kitty
        libnotify
        util-linux
        uwsm
      ];
      text = ''
        root=/etc/nixos
        target="''${1:-}"
        pattern=

        case "$target" in
          stylix)
            title=Stylix
            file=modules/nixos/desktop/appearance/stylix.nix
            pattern='stylix ='
            ;;
          font)
            title=Font
            file=modules/nixos/desktop/appearance/stylix.nix
            pattern='fonts ='
            ;;
          hyprland)
            title=Hyprland
            file=modules/home/desktop/hyprland/configuration.nix
            pattern='hl.config'
            ;;
          waybar)
            title=Waybar
            file=modules/home/desktop/waybar/core.nix
            pattern='programs.waybar'
            ;;
          lock-screen)
            title='Lock Screen'
            file=modules/home/desktop/idle-lock.nix
            pattern='programs.hyprlock'
            ;;
          screensaver)
            title=Screensaver
            file=modules/home/desktop/screensaver/control.nix
            pattern='nixconf-screensaver'
            ;;
          monitor-scaling | displays)
            title=Displays
            file=modules/home/desktop/hyprland/configuration.nix
            pattern='hl.monitor'
            ;;
          graphics)
            title=Graphics
            file=modules/nixos/graphics.nix
            pattern='hardware.graphics'
            ;;
          audio)
            title=Audio
            file=modules/nixos/system/audio.nix
            pattern='services.pipewire'
            ;;
          wifi)
            title=Wi-Fi
            file=modules/nixos/networking.nix
            pattern='wireless.iwd'
            ;;
          bluetooth)
            title=Bluetooth
            file=modules/nixos/system/bluetooth.nix
            pattern='hardware.bluetooth'
            ;;
          power-profile)
            title='Power Profile'
            file=modules/nixos/hardware.nix
            pattern='powerManagement'
            ;;
          system-sleep)
            title='System Sleep'
            file=modules/home/desktop/idle-lock.nix
            pattern='services.hypridle'
            ;;
          keybindings)
            title=Keybindings
            file=modules/home/desktop/hyprland/bindings.nix
            pattern='hl.bind'
            ;;
          input)
            title=Input
            file=modules/home/desktop/hyprland/configuration.nix
            pattern='input ='
            ;;
          dns)
            title=DNS
            file=modules/nixos/networking.nix
            pattern='resolved'
            ;;
          security)
            title=Security
            file=modules/nixos/security.nix
            pattern='security.sudo'
            ;;
          config)
            title='NixOS Config'
            file=.
            ;;
          *)
            printf 'Usage: nixconf-edit <target>\n' >&2
            exit 2
            ;;
        esac

        path="$root/$file"
        if [[ ! -e "$path" ]]; then
          notify-send --app-name=nixconf-menu "Configuration unavailable" "$path does not exist"
          exit 1
        fi

        args=("$path")
        if [[ -n "$pattern" ]]; then
          args=("+/$pattern" "$path")
        fi

        cd "$root"
        exec setsid uwsm app -- kitty --class TUI.float --title "$title" \
          direnv exec "$root" nvim "''${args[@]}"
      '';
    };
  in {
    home.packages = [configEditor];
  };
}
