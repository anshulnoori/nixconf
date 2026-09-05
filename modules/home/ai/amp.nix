{moduleWithSystem, ...}: {
  flake.modules.homeManager.base = moduleWithSystem (
    {config, ...}: {
      home.packages = [config.packages.amp-cli];
    }
  );

  flake.modules.homeManager.desktop = moduleWithSystem (
    {config, ...}: {
      home.packages = [config.packages.amp-desktop];

      xdg.autostart = {
        enable = true;
        entries = [
          "${config.packages.amp-desktop}/share/applications/com.anshulnoori.amp-linux.desktop"
        ];
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications."x-scheme-handler/com.ampcode.amp.macos.auth" = [
          "com.anshulnoori.amp-linux.desktop"
        ];
      };
    }
  );
}
