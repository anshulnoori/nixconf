_: {
  flake.modules.nixos.desktop = {
    config,
    lib,
    pkgs,
    ...
  }: let
    plymouth = lib.getExe' config.boot.plymouth.package "plymouth";
    quitPlymouth = pkgs.writeShellApplication {
      name = "quit-plymouth-after-desktop";
      runtimeInputs = with pkgs; [
        coreutils
        procps
      ];
      text = ''
        if ! ${plymouth} --ping; then
          exit 0
        fi

        desktop_ready=false
        for _ in {1..300}; do
          if pgrep -u mvs -x Hyprland >/dev/null && pgrep -u mvs -x swaybg >/dev/null; then
            desktop_ready=true
            sleep 0.25
            break
          fi
          sleep 0.1
        done

        if [[ "$desktop_ready" == true ]]; then
          exec ${plymouth} quit --retain-splash
        fi

        exec ${plymouth} quit
      '';
    };
  in {
    services = {
      displayManager.regreet.enable = true;

      greetd = {
        greeterManagesPlymouth = true;
        settings.initial_session = {
          command = "${lib.getExe pkgs.uwsm} start -e -D Hyprland hyprland.desktop";
          user = "mvs";
        };
      };
    };

    systemd.services = {
      greetd.serviceConfig.ExecStartPre = "-${plymouth} deactivate";
      plymouth-quit-wait.wantedBy = lib.mkForce [];
      plymouth-quit = {
        after = ["greetd.service"];
        wantedBy = lib.mkForce ["graphical.target"];
        serviceConfig = {
          ExecStart = lib.mkForce [
            ""
            "${quitPlymouth}/bin/quit-plymouth-after-desktop"
          ];
          TimeoutStartSec = "35s";
        };
      };
    };

    security.pam.services = {
      greetd.enableGnomeKeyring = true;
      hyprlock = {};
    };
  };
}
