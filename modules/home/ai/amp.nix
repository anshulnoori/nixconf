{
  inputs,
  moduleWithSystem,
  ...
}: {
  flake.modules.homeManager.base = moduleWithSystem (
    {config, ...}: {
      home.packages = [config.packages.amp-cli];
    }
  );

  flake.modules.homeManager.desktop = {pkgs, ...}: let
    ampDesktop = inputs.monorepo.packages.${pkgs.stdenv.hostPlatform.system}.amp-desktop;
  in {
    home.packages = [ampDesktop];

    xdg.autostart = {
      enable = true;
      entries = [
        "${ampDesktop}/share/applications/com.anshulnoori.amp-linux.desktop"
      ];
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/com.ampcode.amp.macos.auth" = [
        "com.anshulnoori.amp-linux.desktop"
      ];
    };
  };
}
