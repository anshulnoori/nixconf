_: {
  disko.devices.disk.system = {
    type = "disk";
    device = "/dev/disk/by-path/pci-0000:01:00.0-nvme-1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "4G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };

        cryptroot = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            enrollRecovery = true;
            settings.allowDiscards = true;
            extraFormatArgs = [
              "--type"
              "luks2"
              "--pbkdf"
              "argon2id"
              "--cipher"
              "aes-xts-plain64"
              "--key-size"
              "512"
            ];

            content = {
              type = "btrfs";
              extraArgs = ["-f"];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = [
                    "noatime"
                    "compress=zstd:3"
                    "discard=async"
                  ];
                };

                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "noatime"
                    "compress=zstd:3"
                    "discard=async"
                  ];
                };

                "@games" = {
                  mountpoint = "/home/mvs/games";
                  mountOptions = [
                    "noatime"
                    "compress=zstd:3"
                    "discard=async"
                  ];
                };

                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "noatime"
                    "compress=zstd:3"
                    "discard=async"
                  ];
                };

                "@swap" = {
                  mountpoint = "/swap";
                  mountOptions = [
                    "noatime"
                    "discard=async"
                  ];
                  swap.swapfile = {
                    size = "64G";
                    priority = 10;
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  systemd.tmpfiles.rules = ["d /home/mvs/games 0755 mvs users -"];
}
