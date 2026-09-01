{inputs, ...}: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    wallpaper = "${inputs.omarchy-rice}/themes/gruvbox/backgrounds/1-the-backwater.jpg";
  in {
    xdg.dataFile."wallpapers/gruvbox/1-the-backwater.jpg".source = wallpaper;

    systemd.user.services.swaybg = {
      Unit = {
        Description = "Gruvbox desktop wallpaper";
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
