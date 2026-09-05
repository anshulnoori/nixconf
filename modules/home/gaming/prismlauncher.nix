{inputs, ...}: {
  flake.modules.homeManager.gaming = {
    config,
    pkgs,
    ...
  }: let
    dataDirectory = "${config.home.homeDirectory}/games/PrismLauncher";
    prismLauncher = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.prismlauncher;
      flags."--dir" = dataDirectory;
    };
  in {
    home.packages = [prismLauncher];
  };
}
