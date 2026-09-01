{inputs, ...}: {
  flake.modules.nixos.base = {lib, ...}: {
    imports = [inputs.lix-module.nixosModules.default];

    nix.settings = {
      auto-optimise-store = true;
      extra-substituters = [
        "https://anshulnoori.cachix.org"
        "https://attic.xuyh0120.win/lantian"
        "https://afnix-hydra.s3-bulk-web.afnix.fr/"
      ];
      extra-trusted-public-keys = [
        "anshulnoori.cachix.org-1:jzLsepTKLr8/jDh8WdI4uhyimUTDSmxN5ispn1uN/Q0="
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
        "afnix:oqt801y+IwJ09XRtNDQYCKb7zuCw9DQXQk8fDWPkwxM="
      ];
    };
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
