_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    home.packages = [
      (pkgs.callPackage ../../../packages/namespace-devbox.nix {})
    ];
  };
}
