{inputs, ...}: {
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

  flake.modules.nixos.desktop = {
    config,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
    source = "${inputs.omarchy-rice}/themes/flexoki-light/backgrounds/1-orb.png";
    wallpaper = pkgs.runCommand "flexoki-orb-gruvbox.png" {nativeBuildInputs = [pkgs.imagemagick];} ''
      magick ${source} -colorspace gray -negate \
        +level-colors '#${colors.base00}','#${colors.base05}' "$out"
    '';
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
        background = "00${colors.base00}";
        brightForeground = colors.base07;
        brightBackground = colors.base02;
        margin = 32;
        marginGradient = 0;
      };
    };
  };
}
