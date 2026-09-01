_: {
  flake.modules.homeManager.base = {
    config,
    lib,
    pkgs,
    ...
  }: let
    notifier = pkgs.writeShellApplication {
      name = "nixconf-renovate-notifier";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.curl
        pkgs.gnugrep
        pkgs.jq
        pkgs.libnotify
        pkgs.util-linux
      ];
      text = builtins.readFile ../../../scripts/notify-renovate-branches.sh;
    };
  in {
    options.services.nixconf-renovate-notifier.enable =
      lib.mkEnableOption "notifications for new nixconf Renovate branch revisions";

    config = lib.mkIf config.services.nixconf-renovate-notifier.enable {
      systemd.user.services.nixconf-renovate-notifier = {
        Unit.Description = "Check nixconf Renovate branches";
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe notifier;
        };
      };

      systemd.user.timers.nixconf-renovate-notifier = {
        Unit.Description = "Check nixconf Renovate branches every six hours";
        Timer = {
          OnCalendar = "*-*-* 00/6:00:00";
          Persistent = true;
          Unit = "nixconf-renovate-notifier.service";
        };
        Install.WantedBy = ["timers.target"];
      };
    };
  };
}
