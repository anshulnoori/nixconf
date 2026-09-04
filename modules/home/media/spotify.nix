_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home.packages = [pkgs.spotify];

    xdg.mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/spotify" = ["spotify.desktop"];
    };
  };
}
