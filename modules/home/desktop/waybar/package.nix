{inputs, ...}: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    programs.waybar.package = inputs.waybar.packages.${pkgs.stdenv.hostPlatform.system}.waybar;
  };
}
