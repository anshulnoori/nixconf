_: {
  flake.modules.nixos.desktop = {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
