_: {
  flake.modules.nixos.base = {pkgs, ...}: let
    storageHealthCheck = import ./_check.nix {inherit pkgs;};
  in {
    environment.systemPackages = [
      pkgs.nvme-cli
      pkgs.smartmontools
      storageHealthCheck
    ];

    systemd = {
      services.nixconf-storage-health = {
        description = "Check Btrfs and NVMe health";
        wantedBy = ["multi-user.target"];
        after = ["local-fs.target"];
        requires = ["local-fs.target"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${storageHealthCheck}/bin/nixconf-storage-health-check";
          StateDirectory = "nixconf-storage-health";
          StateDirectoryMode = "0755";
        };
      };

      timers.nixconf-storage-health = {
        description = "Check Btrfs and NVMe health daily";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };
    };
  };
}
