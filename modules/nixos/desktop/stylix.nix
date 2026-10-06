{inputs, ...}: {
  flake.modules.nixos.desktop = {pkgs, ...}: {
    imports = [inputs.stylix.nixosModules.stylix];
    stylix = {
      enable = true;
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
    palette = foreground:
      lib.concatStringsSep ", " (with colors; [
        foreground
        base01
        base02
        base03
        base00
        base02
        foreground
        base07
        foreground
        base01
        base00
        base00
        base0D
        base00
        base0D
        base0E
        base02
        foreground
        base01
        foreground
        base04
      ]);
  in {
    stylix.targets.rofi.enable = false;

    qt.qt6ctSettings.Appearance.color_scheme_path = toString (pkgs.writeText "stylix-qt6ct.conf" ''
      [ColorScheme]
      active_colors=${palette colors.base05}
      inactive_colors=${palette colors.base05}
      disabled_colors=${palette colors.base03}
    '');
  };
}
