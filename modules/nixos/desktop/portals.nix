_: {
  flake.modules.nixos.desktop = {pkgs, ...}: {
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [pkgs.xdg-desktop-portal-termfilechooser];

      config.hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.ScreenCast" = ["hyprland"];
        "org.freedesktop.impl.portal.RemoteDesktop" = ["hyprland"];
        "org.freedesktop.impl.portal.AppChooser" = ["gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["termfilechooser"];
        "org.freedesktop.impl.portal.Settings" = ["gtk"];
        "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
      };
    };
  };
}
