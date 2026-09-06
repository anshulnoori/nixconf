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
      package = inputs.hyprpolkitagent.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
        patches = (old.patches or []) ++ [./hyprpolkitagent/compact.patch];
      });
    };

    xdg.configFile."hyprpolkitagent/hyprpolkitagent.conf".text = ''
      general {
        window_width = 420
        window_height = 170
        password_field_width = 380
        show_details = false
      }
    '';

    xdg.configFile."hypr/hyprtoolkit.conf".text = ''
      background = 0xff${colors.base00}
      base = 0xff${colors.base00}
      alternate_base = 0xff${colors.base02}
      text = 0xff${colors.base05}
      bright_text = 0xff${colors.base06}
      link_text = 0xff${colors.base0D}
      accent = 0xff${colors.base0D}
      accent_secondary = 0xff${colors.base0C}
      font_family = ${config.stylix.fonts.monospace.name}
      font_family_monospace = ${config.stylix.fonts.monospace.name}
      font_size = 12
      small_font_size = 11
      h1_size = 16
      h2_size = 14
      h3_size = 12
      rounding_large = 0
      rounding_small = 0
    '';

    wayland.windowManager.hyprland.extraConfig = ''
      hl.window_rule({
        match = { class = "^hyprpolkitagent$" },
        float = true,
        rounding = 0,
        no_anim = true,
        move = { "(monitor_w-window_w-20)", "60" },
      })
    '';
  };
}
