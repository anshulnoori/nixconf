_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    home.packages = [pkgs.nix-output-monitor];
  };
}
