{inputs, ...}: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home.packages = [
      inputs.monorepo.packages.${pkgs.stdenv.hostPlatform.system}.mail-desktop
      pkgs.libsecret
    ];
  };
}
