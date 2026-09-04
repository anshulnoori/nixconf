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

    systemd.services.amd-pstate-performance = {
      description = "Set AMD P-state energy preference to performance";
      wantedBy = ["multi-user.target"];
      after = ["multi-user.target"];
      serviceConfig.Type = "oneshot";
      script = ''
        for preference in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
          if [[ -w "$preference" ]]; then
            echo performance > "$preference"
          fi
        done
      '';
    };
  };
}
