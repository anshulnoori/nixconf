_: {
  flake.modules.nixos.desktop = {pkgs, ...}: {
    boot.initrd.kernelModules = ["amdgpu"];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    programs.obs-studio = {
      enable = true;
      enableVirtualCamera = true;
    };

    programs.gpu-screen-recorder.enable = true;

    environment.systemPackages = [
      pkgs.libva-utils
      pkgs.mesa-demos
      pkgs.vulkan-tools
    ];
  };
}
