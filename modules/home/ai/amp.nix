{moduleWithSystem, ...}: {
  flake.modules.homeManager.base = moduleWithSystem (
    {config, ...}: {
      home.packages = [config.packages.amp-cli];
    }
  );

  flake.modules.homeManager.desktop = moduleWithSystem (
    {config, ...}: {pkgs, ...}: {
      home.packages = [config.packages.amp-desktop pkgs.labwc pkgs.wlr-randr];

      xdg.mimeApps = {
        enable = true;
        defaultApplications."x-scheme-handler/com.ampcode.amp.linux.auth" = ["amp-desktop.desktop"];
      };
    }
  );
}
