_: {
  flake.modules.nixos.desktop.services.udisks2.enable = true;

  flake.modules.homeManager.desktop.services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never";
  };
}
