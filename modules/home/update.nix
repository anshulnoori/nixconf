_: {
  flake.modules.homeManager.base = {
    config,
    lib,
    pkgs,
    ...
  }: let
    updateTool = pkgs.writeShellApplication {
      name = "nixconf-update";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.git
        pkgs.jq
        pkgs.libnotify
        pkgs.nh
        pkgs.procps
        pkgs.ripgrep
        pkgs.util-linux
      ];
      # Keep the user's configured Git identity and signing tools available.
      text =
        ''
          export PATH="${config.home.profileDirectory}/bin:/run/wrappers/bin:/run/current-system/sw/bin:$PATH"
        ''
        + builtins.readFile ../../scripts/nixconf-update.sh;
    };
  in {
    options.services.nixconf-update = {
      enable = lib.mkEnableOption "background NixOS update builds";
      package = lib.mkOption {
        type = lib.types.package;
        readOnly = true;
        default = updateTool;
        internal = true;
      };
    };

    config = lib.mkIf config.services.nixconf-update.enable {
      systemd.user.services.nixconf-update = {
        Unit = {
          Description = "Build local nixconf updates and notify when ready";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${lib.getExe updateTool} scheduled";
          TimeoutStartSec = "6h";
        };
      };

      systemd.user.timers.nixconf-update = {
        Unit.Description = "Update nixconf locally every three days";
        Timer = {
          OnBootSec = "10m";
          OnUnitActiveSec = "3d";
          Unit = "nixconf-update.service";
        };
        Install.WantedBy = ["timers.target"];
      };
    };
  };
}
