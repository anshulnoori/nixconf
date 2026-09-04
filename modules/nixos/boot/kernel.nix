{inputs, ...}: {
  flake.modules.nixos.base = {pkgs, ...}: {
    nixpkgs.overlays = [inputs.nix-cachyos-kernel.overlays.pinned];
    boot.kernelPackages =
      pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-zen4.extend
      (_: linuxPrev: {
        kernel = linuxPrev.kernel.override {bbr3 = true;};
      });
  };
}
