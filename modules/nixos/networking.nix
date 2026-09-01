_: {
  flake.modules.nixos.base = {
    boot.kernelModules = ["tcp_bbr"];
    boot.kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };

    networking = {
      useDHCP = false;
      useNetworkd = true;
      wireless.iwd = {
        enable = true;
        settings.General.EnableNetworkConfiguration = false;
      };
      firewall = {
        enable = true;
        trustedInterfaces = [];
        allowedTCPPorts = [];
        allowedUDPPorts = [];
      };
    };

    services = {
      resolved.enable = true;
      tailscale = {
        enable = true;
        openFirewall = true;
        useRoutingFeatures = "none";
      };
    };
  };
}
