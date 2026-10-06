{moduleWithSystem, ...}: {
  flake.modules.homeManager.base = moduleWithSystem (
    {config, ...}: {
      home.packages = [config.packages.amp-cli];
    }
  );

  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home.packages = [pkgs.labwc pkgs.wlr-randr];
  };
}
