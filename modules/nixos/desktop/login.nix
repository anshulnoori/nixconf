_: {
  flake.modules.nixos.desktop = {
    lib,
    pkgs,
    ...
  }: {
    services = {
      displayManager.regreet.enable = true;

      greetd.settings.initial_session = {
        command = "${lib.getExe pkgs.uwsm} start -e -D Hyprland hyprland.desktop";
        user = "mvs";
      };
    };

    security.pam.services.hyprlock = {};
  };
}
