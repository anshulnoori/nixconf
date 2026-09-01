{inputs, ...}: {
  flake.modules.nixos.desktop = {
    imports = [inputs.hyprland.nixosModules.default];

    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };
  };
}
