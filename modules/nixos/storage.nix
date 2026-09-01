{inputs, ...}: {
  flake.modules.nixos.base = {
    config,
    pkgs,
    ...
  }: {
    imports = [inputs.disko.nixosModules.disko];

    boot = {
      kernelParams = ["zswap.enabled=0"];
      kernel.sysctl = {
        "vm.swappiness" = 150;
        "vm.page-cluster" = 0;
        "vm.vfs_cache_pressure" = 50;
        "vm.dirty_bytes" = 268435456;
        "vm.dirty_background_bytes" = 67108864;
        "vm.dirty_writeback_centisecs" = 1500;
      };
    };

    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 100;
      priority = 100;
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      persistent = true;
    };

    environment.systemPackages = [
      pkgs.nvme-cli
      pkgs.smartmontools
    ];

    services = {
      smartd.enable = true;
      fstrim = {
        enable = true;
        interval = "weekly";
      };
      btrfs.autoScrub = {
        enable = true;
        interval = "monthly";
        fileSystems = ["/"];
      };
      udev.extraRules = ''
        ACTION=="add|change", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="nvme*n*", ATTR{queue/scheduler}=="*kyber*", ATTR{queue/scheduler}="kyber"
      '';
    };

    systemd = {
      tmpfiles.rules = [
        "w /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise"
        "w- /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none - - - - 409"
      ];

      services = {
        nix-gc.serviceConfig.ExecStartPre = "${config.nix.package}/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations +6";
        nixconf-storage-health = {
          description = "Check Btrfs and NVMe health";
          after = ["local-fs.target"];
          requires = ["local-fs.target"];
          path = [
            pkgs.btrfs-progs
            pkgs.nvme-cli
          ];
          script = ''
            btrfs device stats --check /

            for device in /dev/nvme*n1; do
              [[ -b "$device" ]] || continue
              nvme smart-log "$device"
            done
          '';
          serviceConfig.Type = "oneshot";
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
