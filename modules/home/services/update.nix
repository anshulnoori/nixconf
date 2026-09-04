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
        pkgs.curl
        pkgs.git
        pkgs.gnugrep
        pkgs.jq
        pkgs.less
        pkgs.libnotify
        pkgs.nh
        pkgs.procps
        pkgs.util-linux
      ];
      text = builtins.readFile ../../../scripts/nixconf-update.sh;
    };
  in {
    options.services.nixconf-update.enable =
      lib.mkEnableOption "the revision-aware nixconf update workflow";

    config = lib.mkIf config.services.nixconf-update.enable {
      home.packages = [updateTool];

      systemd.user.services.nixconf-update = {
        Unit.Description = "Check nixconf updates";
        Service = {
          Type = "oneshot";
          ExecStart = "${lib.getExe updateTool} check";
        };
      };

      systemd.user.timers.nixconf-update = {
        Unit.Description = "Check nixconf updates every six hours";
        Timer = {
          OnBootSec = "2m";
          OnCalendar = "*-*-* 00/6:00:00";
          Persistent = true;
          Unit = "nixconf-update.service";
        };
        Install.WantedBy = ["timers.target"];
      };
    };
  };
}
