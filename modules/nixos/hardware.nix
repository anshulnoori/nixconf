_: {
  flake.modules.nixos.base = {
    boot.kernelParams = ["amd_pstate=active"];
    powerManagement.cpuFreqGovernor = "performance";

    hardware = {
      enableRedistributableFirmware = true;
    };

    services = {
      fwupd.enable = true;
      power-profiles-daemon.enable = false;
    };
  };
}
