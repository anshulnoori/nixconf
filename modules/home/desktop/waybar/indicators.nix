_: {
  flake.modules.homeManager.desktop = {
    config,
    pkgs,
    ...
  }: let
    captureScreenrecord = "${config.home.profileDirectory}/bin/capture-screenrecord";
    screenrecordingIndicator = pkgs.writeShellApplication {
      name = "nixconf-screenrecording-indicator";
      text = ''
        if ${captureScreenrecord} active; then
          printf '{"text":"󰻂","tooltip":"Stop screen recording","class":"active"}\n'
        else
          printf '{"text":""}\n'
        fi
      '';
    };
  in {
    programs.waybar.settings.mainBar = {
      "custom/screenrecording" = {
        exec = "${screenrecordingIndicator}/bin/nixconf-screenrecording-indicator";
        return-type = "json";
        interval = 1;
        signal = 8;
        on-click = "${captureScreenrecord} stop";
      };
      "custom/update" = {
        exec = "${config.services.nixconf-update.package}/bin/nixconf-update waybar";
        return-type = "json";
        interval = 5;
        signal = 10;
        on-click = "${config.home.profileDirectory}/bin/present-terminal 'NixOS Update' ${config.services.nixconf-update.package}/bin/nixconf-update apply";
      };
    };
  };
}
