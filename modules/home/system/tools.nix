_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home.packages = with pkgs; [
      libva-utils
      mesa-demos
      pciutils
      usbutils
      vulkan-tools
    ];
  };
}
