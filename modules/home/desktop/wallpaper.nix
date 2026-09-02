{inputs, ...}: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    wallpaper = "${inputs.omarchy-rice}/themes/flexoki-light/backgrounds/1-orb.png";
  in {
    xdg.dataFile."wallpapers/flexoki-light/1-orb.png".source = wallpaper;

    systemd.user.services.swaybg = {
      Unit = {
        Description = "Flexoki Light desktop wallpaper";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
