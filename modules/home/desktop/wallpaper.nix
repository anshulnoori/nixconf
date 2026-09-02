{inputs, ...}: {
  flake.modules.homeManager.desktop = {
    config,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
    source = "${inputs.omarchy-rice}/themes/flexoki-light/backgrounds/1-orb.png";
    relativePath = "wallpapers/gruvbox/flexoki-orb.png";
    wallpaperPath = "${config.xdg.dataHome}/${relativePath}";
    wallpaper = pkgs.runCommand "flexoki-orb-gruvbox.png" {nativeBuildInputs = [pkgs.imagemagick];} ''
      magick ${source} -colorspace gray -negate \
        +level-colors '#${colors.base00}','#${colors.base05}' "$out"
    '';
  in {
    xdg.dataFile.${relativePath}.source = wallpaper;

    systemd.user.services.swaybg = {
      Unit = {
        Description = "Gruvbox Flexoki Orb desktop wallpaper";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${wallpaperPath} -m fill";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
