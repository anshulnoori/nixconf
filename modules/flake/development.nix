{lib, ...}: {
  perSystem = {
    config,
    pkgs,
    system,
    ...
  }: let
    installerShell = pkgs.mkShellNoCC {
      packages = [
        config.packages.amp-cli
        pkgs.bat
        pkgs.curl
        pkgs.dmidecode
        pkgs.ethtool
        pkgs.fwupd
        pkgs.git
        pkgs.gnugrep
        pkgs.iproute2
        pkgs.iputils
        pkgs.jq
        pkgs.kmod
        pkgs.less
        pkgs.lm_sensors
        pkgs.magic-wormhole
        pkgs.nvme-cli
        pkgs.openssh
        pkgs.pciutils
        pkgs.ripgrep
        pkgs.rsync
        pkgs.smartmontools
        pkgs.tmux
        pkgs.usbutils
        pkgs.util-linux
      ];
    };
  in {
    devShells =
      {
        default = pkgs.mkShellNoCC {
          packages =
            config.pre-commit.settings.enabledPackages
            ++ [
              pkgs.bun
              pkgs.cachix
              pkgs.git
              pkgs.jq
              pkgs.nil
              pkgs.pre-commit
              pkgs.renovate
            ];
          shellHook = config.pre-commit.installationScript;
        };
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        installer = installerShell;
      };
  };
}
