{inputs, ...}: {
  flake.modules.nixos.desktop = {pkgs, ...}: let
    hyprlandPkgs = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  in {
    boot.initrd.kernelModules = ["amdgpu"];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      package = hyprlandPkgs.mesa;
      package32 = hyprlandPkgs.pkgsi686Linux.mesa;
    };
  };
}
