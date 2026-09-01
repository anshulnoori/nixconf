_: {
  flake.modules.nixos.base = {
    boot.loader = {
      timeout = 5;
      efi.canTouchEfiVariables = true;
      limine = {
        enable = true;
        maxGenerations = 6;
        secureBoot.enable = false;
      };
    };
  };
}
