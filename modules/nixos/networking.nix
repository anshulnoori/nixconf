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
      resolved = {
        enable = true;
        settings.Resolve = {
          DNS = "1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com";
          FallbackDNS = "2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com";
          DNSOverTLS = true;
        };
      };
      tailscale = {
        enable = true;
        openFirewall = true;
        useRoutingFeatures = "none";
      };
    };
  };

  flake.modules.nixos.desktop.hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}
