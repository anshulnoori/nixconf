{inputs, ...}: {
  flake.modules.homeManager.desktop = {
    config,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
  in {
    services.hyprpolkitagent = {
      enable = true;
      package = inputs.hyprpolkitagent.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };

    xdg.configFile."hypr/hyprtoolkit.conf".text = ''
      background = 0xff${colors.base00}
      base = 0xff${colors.base01}
      alternate_base = 0xff${colors.base02}
      text = 0xff${colors.base05}
      bright_text = 0xff${colors.base06}
      link_text = 0xff${colors.base0D}
      accent = 0xff${colors.base0D}
      accent_secondary = 0xff${colors.base0C}
      font_family = ${config.stylix.fonts.sansSerif.name}
      font_family_monospace = ${config.stylix.fonts.monospace.name}
      font_size = 13
      small_font_size = 11
      h1_size = 22
      h2_size = 18
      h3_size = 15
      rounding_large = 4
      rounding_small = 2
    '';
  };
}
