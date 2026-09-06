_: {
  flake.modules.nixos.gaming = {pkgs, ...}: {
    programs.steam = {
      enable = true;
      extraCompatPackages = [(pkgs.callPackage ../../../packages/proton-ge.nix {})];
      protontricks.enable = true;
    };
  };
}
