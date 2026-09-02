{inputs, ...}: {
  flake.modules.homeManager.desktop = {
    config,
    lib,
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
    options.nixconf.desktop.wallpaper = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
    };

    config = {
      nixconf.desktop.wallpaper = wallpaper;
      xdg.dataFile."wallpapers/gruvbox/flexoki-orb.png".source = config.nixconf.desktop.wallpaper;

      systemd.user.services.swaybg = {
        Unit = {
          Description = "Gruvbox Flexoki Orb desktop wallpaper";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${config.nixconf.desktop.wallpaper} -m fill";
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = ["graphical-session.target"];
      };
    };
  };
}
