{inputs, ...}: {
  flake.modules.nixos.desktop = {pkgs, ...}: {
    imports = [inputs.stylix.nixosModules.stylix];
    stylix = {
      enable = true;
      # Evaluation must not require a built package in a fresh CI store.
      base16Scheme = "${inputs.stylix.inputs.tinted-schemes}/base16/gruvbox-dark-hard.yaml";
      polarity = "dark";
      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font";
        };
        sansSerif = {
          package = pkgs.callPackage ../../../packages/sf-pro.nix {};
          name = "SF Pro Text";
        };
      };
      targets.limine.enable = false;
      targets.plymouth.enable = false;
    };
  };

  flake.modules.homeManager.desktop = {
    config,
    lib,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors.withHashtag;
    # qtct stores QPalette roles in enum order, including the unused NoRole slot.
    palette = foreground:
      lib.concatStringsSep ", " (with colors; [
        foreground # WindowText
        base01 # Button
        base02 # Light
        base03 # Midlight
        base00 # Dark
        base02 # Mid
        foreground # Text
        base07 # BrightText
        foreground # ButtonText
        base01 # Base
        base00 # Window
        base00 # Shadow
        base0D # Highlight
        base00 # HighlightedText
        base0D # Link
        base0E # LinkVisited
        base02 # AlternateBase
        foreground # NoRole
        base01 # ToolTipBase
        foreground # ToolTipText
        base04 # PlaceholderText
      ]);
  in {
    # Walker owns the launcher; do not generate a theme for unused Rofi.
    stylix.targets.rofi.enable = false;

    # Kvantum styles widgets, but Qt Quick also needs a Qt platform palette.
    qt.qt6ctSettings.Appearance.color_scheme_path = toString (pkgs.writeText "stylix-qt6ct.conf" ''
      [ColorScheme]
      active_colors=${palette colors.base05}
      inactive_colors=${palette colors.base05}
      disabled_colors=${palette colors.base03}
    '');
  };
}
