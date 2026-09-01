_: {
  flake.modules.nixos.base = {
    users = {
      mutableUsers = true;
      users.root.hashedPassword = "!";
    };
    systemd.sysusers.enable = false;

    security.sudo = {
      execWheelOnly = true;
      wheelNeedsPassword = true;
    };
  };
}
