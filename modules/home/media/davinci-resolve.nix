_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home.packages = [(pkgs.callPackage ../../../packages/davinci-resolve.nix {})];
  };
}
