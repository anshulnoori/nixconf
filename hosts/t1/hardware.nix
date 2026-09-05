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
  };

  # Keychron Launcher needs raw HID access. Tag before 73-seat-late.rules
  # so logind grants access only to the active local session.
  services.udev.packages = [
    (pkgs.writeTextDir "lib/udev/rules.d/70-keychron-c1-pro-8k.rules" ''
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0521", TAG+="uaccess"
    '')
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
