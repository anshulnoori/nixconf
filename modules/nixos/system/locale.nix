_: {
  flake.modules.nixos.base = {
    console.keyMap = "us";
    i18n.defaultLocale = "en_US.UTF-8";
    services.automatic-timezoned.enable = true;
  };
}
