_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    home.packages = with pkgs; [
      dix
      nix-output-monitor
      nix-tree
      nvd
    ];
  };
}
