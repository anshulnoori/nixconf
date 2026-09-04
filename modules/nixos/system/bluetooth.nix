_: {
  flake.modules.nixos.desktop = {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      # LibrePods' experimental Apple-device features require DID spoofing.
      settings.General.DeviceID = "bluetooth:004C:0000:0000";
    };
    programs.librepods.enable = true;
  };
}
