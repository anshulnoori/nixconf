{inputs, ...}: {
  flake.modules.nixos.desktop = {pkgs, ...}: {
    imports = [inputs.hyprland.nixosModules.default];

    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland.overrideAttrs (previous: {
        patches = (previous.patches or []) ++ [./hyprland-idle-inhibit.patch];
      });
      withUWSM = true;
      xwayland.enable = true;
    };
  };
}
