{inputs, ...}: {
  flake.modules.nixos.base = {pkgs, ...}: {
    nixpkgs.overlays = [
      inputs.nix-cachyos-kernel.overlays.pinned
      (final: prev: {
        aggregateModules = modules:
          (prev.aggregateModules modules).overrideAttrs (old: {
            postBuild =
              builtins.replaceStrings
              [
                "cp --no-preserve=mode,ownership --remove-destination"
                "xargs -d'\\n' cat >> modules.cer"
              ]
              [
                "test -e modules.cer || ln -sf ${final.emptyFile} modules.cer\n        cp --no-preserve=mode,ownership --remove-destination"
                "xargs -d'\\n' ${final.runtimeShell} -c 'for f; do if test -e \"$f\"; then cat \"$f\"; fi; done' sh >> modules.cer"
              ]
              old.postBuild;
          });
      })
    ];
    boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-zen4;
  };
}
