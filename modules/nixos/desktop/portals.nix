{inputs, ...}: {
  flake.modules.nixos.desktop = {pkgs, ...}: let
    ampPackages = inputs.monorepo.packages.${pkgs.stdenv.hostPlatform.system};
  in {
    nixpkgs.overlays = [
      (_final: _previous: {
        xdg-desktop-portal = ampPackages.xdg-desktop-portal-credential;
      })
    ];

    services = {
      pcscd.enable = true;
      udev.packages = [pkgs.libfido2];
    };

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-hyprland
        ampPackages.credentialsd
      ];

      config.hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.ScreenCast" = ["hyprland"];
        "org.freedesktop.impl.portal.RemoteDesktop" = ["hyprland"];
        "org.freedesktop.impl.portal.AppChooser" = ["gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
        "org.freedesktop.impl.portal.Settings" = ["gtk"];
        "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
        "org.freedesktop.impl.portal.experimental.Credential" = ["credentialsd"];
      };
    };

    systemd.user.services.xdg-desktop-portal = {
      overrideStrategy = "asDropin";
      environment.XDG_DESKTOP_PORTAL_ENABLE_EXPERIMENTAL = "credential";
    };
  };
}
