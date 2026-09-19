_: {
  flake.modules.homeManager.desktop = {
    config,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
  in {
    stylix.targets.mako.enable = false;

    services.mako = {
      enable = true;
      settings = {
        anchor = "top-right";
        group-by = "app-name,summary,body";
        default-timeout = 5000;
        width = 320;
        outer-margin = 8;
        padding = "8,10";
        border-size = 2;
        border-radius = 0;
        max-icon-size = 24;
        font = "${config.stylix.fonts.monospace.name} 10";
        text-color = "#${colors.base05}";
        border-color = "#${colors.base0D}";
        background-color = "#${colors.base00}";
        "mode=do-not-disturb".invisible = true;
        "mode=do-not-disturb app-name=notify-send".invisible = false;
        "mode=do-not-disturb app-name=nixconf-menu".invisible = false;
        "mode=do-not-disturb app-name=nixconf-capture".invisible = false;
        "mode=do-not-disturb app-name=nixconf-update".invisible = false;
        "app-name=nixconf-menu" = {
          anchor = "bottom-center";
        };
        "urgency=critical" = {
          default-timeout = 0;
          layer = "overlay";
        };
        "app-name=nixconf-update" = {
          default-timeout = 10000;
          layer = "overlay";
        };
        "app-name=nixconf-update summary=\"Update Available\"" = {
          on-button-left = "exec ${pkgs.mako}/bin/makoctl dismiss -n \"$id\"; ${config.home.profileDirectory}/bin/present-terminal 'NixOS Update' ${pkgs.nh}/bin/nh os switch /etc/nixos --ask --diff always";
          on-touch = "exec ${pkgs.mako}/bin/makoctl dismiss -n \"$id\"; ${config.home.profileDirectory}/bin/present-terminal 'NixOS Update' ${pkgs.nh}/bin/nh os switch /etc/nixos --ask --diff always";
        };
        "summary~=\"Screenshot saved\"" = {
          max-icon-size = 64;
          on-button-left = "invoke-default-action";
          format = "<b>%s</b>\\n%b";
        };
        "summary~=\"Screen recording saved\"" = {
          max-icon-size = 64;
          on-button-left = "invoke-default-action";
          format = "<b>%s</b>\\n%b";
        };
      };
    };
  };
}
