_: {
  systemd.network.networks = {
    "10-enp11s0" = {
      matchConfig.Name = "enp11s0";
      networkConfig = {
        DHCP = "yes";
        DNS = [
          "1.1.1.1#cloudflare-dns.com"
          "1.0.0.1#cloudflare-dns.com"
        ];
        DNSDefaultRoute = true;
        IPv6AcceptRA = true;
      };
      dhcpV4Config.UseDNS = false;
      ipv6AcceptRAConfig.UseDNS = false;
      linkConfig.RequiredForOnline = "routable";
    };

    "20-wlp12s0" = {
      matchConfig.Name = "wlp12s0";
      networkConfig = {
        DHCP = "yes";
        DNS = [
          "1.1.1.1#cloudflare-dns.com"
          "1.0.0.1#cloudflare-dns.com"
        ];
        DNSDefaultRoute = true;
        IPv6AcceptRA = true;
      };
      dhcpV4Config.UseDNS = false;
      ipv6AcceptRAConfig.UseDNS = false;
      linkConfig.RequiredForOnline = "no";
    };
  };
}
