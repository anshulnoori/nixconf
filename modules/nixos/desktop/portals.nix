_: {
  flake.modules.nixos.desktop = {pkgs, ...}: let
    luminous = pkgs.xdg-desktop-portal-luminous.overrideAttrs (finalAttrs: previousAttrs: {
      version = "0.1.21-unstable-2026-09-16";
      src = pkgs.fetchFromGitHub {
        owner = "waycrate";
        repo = "xdg-desktop-portal-luminous";
        rev = "9ca09f5f4233517ee986622305d0a4e2faeb5e29";
        hash = "sha256-OIpnu5R5PhxuHGtL/YEPN4pyJsrhrT5VzhJ1WkGJjsI=";
      };
      patches = (previousAttrs.patches or []) ++ [./luminous-eis-regions.patch ./luminous-eis-scroll.patch];
      cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname version src;
        hash = "sha256-3+h7QqrAz8u4MMycQWJ8ioFSjvzAomEFZBhDSj9xjwU=";
      };
      doCheck = true;
      checkPhase = ''
        runHook preCheck
        cargo test --offline --release --bin xdg-desktop-portal-luminous
        runHook postCheck
      '';
    });
  in {
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [pkgs.xdg-desktop-portal-termfilechooser luminous];

      config.hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.ScreenCast" = ["hyprland"];
        "org.freedesktop.impl.portal.RemoteDesktop" = ["luminous"];
        "org.freedesktop.impl.portal.AppChooser" = ["gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["termfilechooser"];
        "org.freedesktop.impl.portal.Settings" = ["gtk"];
        "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
      };
    };
  };
}
