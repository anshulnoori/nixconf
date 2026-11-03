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
    kernelModules = ["kvm-amd"];
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
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
