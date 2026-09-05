_: {
  flake.modules.nixos.desktop = {lib, ...}: {
    services.gnome = {
      gcr-ssh-agent.enable = false;
      gnome-keyring.enable = true;
    };

    security.pam.services.login.enableGnomeKeyring = lib.mkForce false;
    security.pam.services.sddm.enableGnomeKeyring = true;
  };
}
