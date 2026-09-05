{inputs, ...}: {
  flake.modules.homeManager.base = {
    imports = [inputs.nix-index-database.homeModules.default];

    programs.nix-index = {
      enable = true;
      enableZshIntegration = false;
    };

    programs.nix-index-database.comma.enable = true;
  };
}
