_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    home.packages = [pkgs.aria2];
  };
}
