_: {
  flake.modules.homeManager.desktop.services.gnome-keyring = {
    enable = true;
    components = ["secrets"];
  };
}
