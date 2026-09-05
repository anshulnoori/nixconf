{inputs, ...}: {
  perSystem = {
    lib,
    pkgs,
    system,
    ...
  }: let
    host = inputs.self.nixosConfigurations.t1.config;
    home = host.home-manager.users.mvs;
    packages = inputs.monorepo.packages.${system};
    desktopFile = "com.anshulnoori.amp-linux.desktop";
    hyprlandPortals = builtins.filter (package: lib.getName package == "xdg-desktop-portal-hyprland") host.xdg.portal.extraPortals;
  in {
    checks = lib.optionalAttrs (system == "x86_64-linux") {
      amp-desktop-user-units = assert lib.assertMsg (hyprlandPortals == [host.programs.hyprland.portalPackage]) "Exactly the Hyprland-matched portal must be registered";
        host.environment.etc."systemd/user".source;

      amp-desktop = assert lib.assertMsg (builtins.elem packages.amp-desktop home.home.packages) "Amp must use the monorepo package";
      assert lib.assertMsg (builtins.elem "${packages.amp-desktop}/share/applications/${desktopFile}" home.xdg.autostart.entries) "Amp autostart is missing";
      assert lib.assertMsg (home.xdg.mimeApps.defaultApplications."x-scheme-handler/com.ampcode.amp.macos.auth" == [desktopFile]) "Amp callback handler is missing";
      assert lib.assertMsg (inputs.self.nixosConfigurations.t1.pkgs.xdg-desktop-portal == packages.xdg-desktop-portal-credential) "Credential portal must use the monorepo package";
      assert lib.assertMsg (builtins.elem packages.credentialsd host.xdg.portal.extraPortals) "credentialsd is missing";
      assert lib.assertMsg (host.xdg.portal.config.hyprland."org.freedesktop.impl.portal.experimental.Credential" == "credentialsd") "Credential portal routing is missing";
      assert lib.assertMsg (host.xdg.portal.config.hyprland."org.freedesktop.impl.portal.AppChooser" == "gtk") "GTK AppChooser must be preserved";
      assert lib.assertMsg (host.systemd.user.services.xdg-desktop-portal.environment.XDG_DESKTOP_PORTAL_ENABLE_EXPERIMENTAL == "credential") "Experimental credential portal is disabled";
      assert lib.assertMsg (host.services.gnome.gnome-keyring.enable && host.security.pam.services.sddm.enableGnomeKeyring) "SDDM keyring unlocking is disabled";
      assert lib.assertMsg (lib.versionAtLeast host.boot.kernelPackages.kernel.version "6.5" && host.services.dbus.implementation == "broker" && lib.versionAtLeast host.services.dbus.brokerPackage.version "34") "Credential portal requires ProcessFD support";
        pkgs.runCommand "nixconf-amp-desktop" {} ''
          test -x ${packages.amp-desktop}/bin/amp-desktop
          test -r ${packages.amp-desktop}/share/applications/${desktopFile}
          touch "$out"
        '';
    };
  };
}
