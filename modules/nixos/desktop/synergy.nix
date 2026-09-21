_: {
  flake.modules.nixos.desktop = {pkgs, ...}: let
    dragon = pkgs.callPackage ../../../packages/synergy-dragon.nix {};
    binaries = "${dragon}/lib/synergy-dragon";
  in {
    environment.systemPackages = [dragon];

    networking.firewall = {
      allowedTCPPorts = [24801];
      allowedUDPPorts = [5353];
    };

    users.groups.synergy-dragon = {};
    users.users.synergy-dragon = {
      isSystemUser = true;
      group = "synergy-dragon";
      home = "/var/lib/synergy-dragon";
    };

    systemd.services.synergy-dragon = {
      description = "Synergy Dragon Alpha service";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "exec";
        User = "synergy-dragon";
        Group = "synergy-dragon";
        ExecStartPre = "${binaries}/synergy-dragon-service seed";
        ExecStart = "${binaries}/synergy-dragon-service";
        Restart = "on-failure";
        RestartSec = 2;
        RuntimeDirectory = "synergy-dragon";
        RuntimeDirectoryMode = "0755";
        StateDirectory = "synergy-dragon";
        StateDirectoryMode = "0755";
        ProtectSystem = "full";
      };
    };

    systemd.user.services."app-synergy\\x2ddragon" = {
      description = "Synergy Dragon Alpha session agent";
      aliases = ["synergy-dragon-agent.service"];
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target"];
      wantedBy = ["graphical-session.target"];
      unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
      serviceConfig = {
        Type = "exec";
        ExecStart = "${binaries}/synergy-dragon-agent";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
