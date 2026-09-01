_: {
  flake.modules.nixos.desktop = {pkgs, ...}: {
    boot.initrd.kernelModules = ["amdgpu"];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    environment.systemPackages = [
      pkgs.libva-utils
      pkgs.mesa-demos
      pkgs.vulkan-tools
    ];
  };
}
