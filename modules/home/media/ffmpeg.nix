_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home.packages = [pkgs.ffmpeg-full];
  };
}
