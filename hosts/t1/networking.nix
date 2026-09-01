_: {
  systemd.network.networks = {
    "10-enp11s0" = {
      matchConfig.Name = "enp11s0";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };

    "20-wlp12s0" = {
      matchConfig.Name = "wlp12s0";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "no";
    };
  };
}
