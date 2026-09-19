{inputs, ...}: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    home.packages = [
      inputs.monorepo.packages.${pkgs.stdenv.hostPlatform.system}.namespace-devbox
    ];
  };
}
