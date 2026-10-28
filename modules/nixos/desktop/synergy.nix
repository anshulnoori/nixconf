_: {
  flake.modules.nixos.desktop = {
    lib,
    pkgs,
    ...
  }: let
    dragon = pkgs.callPackage ../../../packages/synergy-dragon.nix {};
    binaries = "${dragon}/lib/synergy-dragon";
    seed = pkgs.writeShellScript "synergy-dragon-seed" ''
      marker=/var/lib/synergy-dragon/nix-seeded-bundle
      if [ "$(cat "$marker" 2>/dev/null)" != "${dragon.updateBundle}" ]; then
        ${binaries}/synergy-dragon-service seed
        echo "${dragon.updateBundle}" > "$marker"
      fi
    '';
  in {
    environment.systemPackages = [dragon];
    system.extraDependencies = [dragon.src dragon.updateBundle];

    programs.nix-ld.libraries = with pkgs; [
      webkitgtk_4_1
      gtk3
      glib
      gdk-pixbuf
      libsoup_3
      qt6.qtbase
      libei
      openssl
      libx11
      libxkbfile
      libxtst
      libxext
      libxinerama
      libxrandr
      libxi
      libxkbcommon
      stdenv.cc.cc.lib
    ];

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
      startLimitIntervalSec = 60;
      startLimitBurst = 5;
      serviceConfig = {
        Type = "exec";
        User = "synergy-dragon";
        Group = "synergy-dragon";
        ExecStartPre = seed;
        ExecStart = "${binaries}/synergy-dragon-launcher";
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
      environment.QT_PLUGIN_PATH = with pkgs.qt6; lib.makeSearchPath qtbase.qtPluginPrefix [qtbase qtwayland];
      serviceConfig = {
        Type = "exec";
        ExecStart = "${binaries}/synergy-dragon-agent";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
