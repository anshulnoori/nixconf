{inputs, ...}: {
  flake.modules.nixos.base = {pkgs, ...}: {
    nixpkgs.overlays = [inputs.nix-cachyos-kernel.overlays.pinned];
    boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-zen4;
  };
}
