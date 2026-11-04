{moduleWithSystem, ...}: {
  flake.modules.homeManager.base = moduleWithSystem (
    {config, ...}: {
      home.packages = [config.packages.amp-cli];
    }
  );

  flake.modules.homeManager.desktop = moduleWithSystem (
    {config, ...}: {pkgs, ...}: {
      home.packages = [config.packages.amp-desktop pkgs.labwc pkgs.wlr-randr];
    }
  );
}
