{inputs, ...}: {
  flake.modules.nixos.base = {lib, ...}: {
    imports = [inputs.lix-module.nixosModules.default];

    nix.settings.auto-optimise-store = true;
    nixpkgs.config.allowUnfreePredicate = package:
      builtins.elem (lib.getName package) ["amp-cli"];

    console.keyMap = "us";
    i18n.defaultLocale = "en_US.UTF-8";
    services = {
      automatic-timezoned.enable = true;
      journald.storage = "persistent";
    };

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

    system.stateVersion = "26.05";
  };
}
