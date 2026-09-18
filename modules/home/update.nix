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
        pkgs.gnugrep
        pkgs.jq
        pkgs.libnotify
        pkgs.nh
        pkgs.procps
        pkgs.util-linux
      ];
      # Keep the user's signing tools and privileged activation wrapper available.
      text =
        ''
          export PATH="${config.home.profileDirectory}/bin:/run/wrappers/bin:/run/current-system/sw/bin:$PATH"
        ''
        + builtins.readFile ../../scripts/nixconf-update.sh;
    };
  in {
    options.services.nixconf-update.enable =
      lib.mkEnableOption "the revision-aware nixconf update workflow";

    config = lib.mkIf config.services.nixconf-update.enable {
      home.packages = [updateTool];

      systemd.user.services.nixconf-update = {
        Unit = {
          Description = "Generate, sign, switch, and publish local nixconf updates";
          # Activation must not interrupt its own switch-before-push transaction.
          X-SwitchMethod = "keep-old";
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
