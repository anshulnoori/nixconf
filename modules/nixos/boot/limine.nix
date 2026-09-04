_: {
  flake.modules.nixos.base = {
    boot.loader = {
      timeout = 5;
      efi.canTouchEfiVariables = true;
      limine = {
        enable = true;
        maxGenerations = 6;
      };
    };
  };

  flake.modules.nixos.desktop = {config, ...}: let
    colors = config.lib.stylix.colors;
    # Reuse the exact build-time Hyprlock render used by the LUKS splash.
    wallpaper = "${builtins.head config.boot.plymouth.themePackages}/share/plymouth/themes/${config.boot.plymouth.theme}/background.png";
  in {
    boot.loader.limine.style = {
      wallpapers = [wallpaper];
      interface = {
        branding = "";
        helpHidden = true;
      };
      graphicalTerminal = {
        palette = "${colors.base00};${colors.base08};${colors.base0B};${colors.base0A};${colors.base0D};${colors.base0E};${colors.base0C};${colors.base05}";
        brightPalette = "${colors.base03};${colors.base08};${colors.base0B};${colors.base0A};${colors.base0D};${colors.base0E};${colors.base0C};${colors.base07}";
        foreground = colors.base05;
        background = "80${colors.base00}";
        brightForeground = colors.base07;
        brightBackground = colors.base02;
        margin = 32;
        marginGradient = 0;
      };
    };
  };
}
