_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    home.packages = [
      pkgs.bat
      pkgs.fd
      pkgs.jq
      pkgs.ripgrep
    ];
  };
}
