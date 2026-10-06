_: {
  flake.modules.homeManager.desktop = {
    config,
    pkgs,
    ...
  }: {
    home.packages = [pkgs.libsecret];

    xdg.desktopEntries.mail = {
      name = "Mail";
      exec = "${pkgs.appimage-run}/bin/appimage-run ${config.xdg.dataHome}/mail-desktop/Mail_0.2.0_x86_64.AppImage";
      terminal = false;
      categories = ["Network" "Email"];
    };
  };
}
