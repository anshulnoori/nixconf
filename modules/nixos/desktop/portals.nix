_: {
  flake.modules.nixos.desktop = {
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      config.hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.AppChooser" = ["gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
        "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
      };
    };
  };
}
