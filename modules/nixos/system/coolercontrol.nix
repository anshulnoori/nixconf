_: {
  flake.modules.nixos.desktop = {pkgs, ...}: {
    environment.systemPackages = [pkgs.lm_sensors];

    programs.coolercontrol.enable = true;

    systemd.services.coolercontrold.environment = {
      CC_HOST_IP4 = "127.0.0.1";
      CC_HOST_IP6 = "";
      CC_PORT = "11987";
    };
  };
}
