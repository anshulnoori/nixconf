{moduleWithSystem, ...}: {
  flake.modules.homeManager.base = moduleWithSystem (
    {config, ...}: {
      home.packages = [config.packages.amp-cli];
    }
  );
}
