{
  config,
  lib,
  pkgs,
  ...
}: {
  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci_prom21"
      "ahci"
      "xhci_pci"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];
    # ddcci-backlight exposes the monitor as a backlight device, so the brightness keys control it.
    extraModulePackages = [config.boot.kernelPackages.ddcci-driver];
    kernelModules = ["kvm-amd" "ddcci-backlight"];
    # Enable HDMI 2.1 FRL (0x400, opt-in since Linux 7.2) on top of the default mask (0x2),
    # so the XG27AQDMGR can run 1440p at 240 Hz over HDMI. FRL links do not support VRR yet.
    kernelParams = ["amdgpu.dcfeaturemask=0x402"];
  };

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb.withPlugins [pkgs.openrgb-plugin-effects];
  };

  services.udev.packages = [
    (pkgs.writeTextDir "lib/udev/rules.d/70-keychron-c1-pro-8k.rules" ''
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0521", TAG+="uaccess"
    '')
    # Since Linux 6.8 no I2C adapter is marked as DDC, so ddcci cannot probe monitors itself.
    # Register the DDC/CI address on each amdgpu display bus instead.
    (pkgs.writeTextDir "lib/udev/rules.d/70-ddcci.rules" ''
      SUBSYSTEM=="i2c", KERNEL=="i2c-[0-9]*", ACTION=="add", ATTR{name}=="AMDGPU DM*", ATTR{new_device}="ddcci 0x37"
    '')
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
