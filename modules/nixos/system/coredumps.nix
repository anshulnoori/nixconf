_: {
  flake.modules.nixos.base = {
    systemd = {
      coredump.enable = false;
      settings.Manager.DefaultLimitCORE = 0;
      user.settings.Manager.DefaultLimitCORE = 0;
    };

    security.pam.loginLimits = [
      {
        domain = "*";
        type = "-";
        item = "core";
        value = "0";
      }
    ];
  };
}
