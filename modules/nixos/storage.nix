{inputs, ...}: {
  flake.modules.nixos.base = {
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

    programs.nh = {
      enable = true;
      flake = "/etc/nixos";
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 6 --keep-one";
      };
    };

    services = {
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
    };
  };
}
