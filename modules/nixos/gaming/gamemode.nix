_: {
  flake.modules.nixos.gaming = {config, ...}: {
    programs.gamemode.enable = true;
    programs.steam.extraPackages = [config.programs.gamemode.package];
  };
}
