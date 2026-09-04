_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    home.packages = with pkgs; [
      aria2
      nmap
      xh
    ];
  };
}
