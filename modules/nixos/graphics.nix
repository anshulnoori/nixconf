{inputs, ...}: {
  flake.modules.nixos.desktop = {pkgs, ...}: let
    # Hyprland is built against its own pinned nixpkgs. Mesa's GBM driver is loaded into
    # Hyprland's process, so it must come from the same glibc, or Hyprland cannot start.
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
