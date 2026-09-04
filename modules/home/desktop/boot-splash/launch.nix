_: {
  flake.modules.homeManager.desktop = {
    config,
    lib,
    pkgs,
    ...
  }: let
    application = import ./_application.nix {
      inherit pkgs;
      colors = config.lib.stylix.colors;
    };
    launcher = pkgs.writeShellApplication {
      name = "nixconf-boot-splash-run";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.systemd
      ];
      text = ''
        background=/run/nixconf-boot/background.png
        if [[ ! -r "$background" ]]; then
          background=${lib.escapeShellArg (toString config.nixconf.desktop.wallpaper)}
        fi

        splash_pid=
        cleanup() {
          if [[ -n "$splash_pid" ]] && kill -0 "$splash_pid" 2>/dev/null; then
            kill "$splash_pid" 2>/dev/null || true
            wait "$splash_pid" 2>/dev/null || true
          fi
        }
        trap cleanup EXIT INT TERM

        # Hyprland normally exports a live socket before emitting its start event.
        # Retrying here also covers unusually slow Wayland socket creation.
        for _ in {1..40}; do
          if [[ -n "''${WAYLAND_DISPLAY:-}" \
            && -S "''${XDG_RUNTIME_DIR:-/run/user/$UID}/$WAYLAND_DISPLAY" ]]; then
            break
          fi
          sleep 0.05
        done

        ${lib.getExe' application "nixconf-boot-splash"} "$background" 2>/dev/null &
        splash_pid=$!

        for _ in {1..100}; do
          if systemctl --user is-active --quiet swaybg.service \
            && systemctl --user is-active --quiet waybar.service; then
            sleep 0.25
            break
          fi
          kill -0 "$splash_pid" 2>/dev/null || exit 0
          sleep 0.25
        done
      '';
    };
  in {
    home.packages = [launcher];

    wayland.windowManager.hyprland.extraConfig = ''
      hl.layer_rule({
        match = { namespace = "nixconf-boot-splash" },
        no_anim = true,
        animation = "none",
      })

      hl.on("hyprland.start", function()
        hl.exec_cmd("${lib.getExe launcher}")
      end)
    '';
  };
}
