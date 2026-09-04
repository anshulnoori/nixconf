_: {
  flake.modules.nixos.base = {
    boot.kernelModules = [
      "sch_fq"
      "tcp_bbr3"
    ];
    boot.kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr3";
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
}
