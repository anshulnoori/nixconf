_: {
  flake.modules.homeManager.desktop = {config, ...}: let
    colors = config.lib.stylix.colors;
  in {
    stylix.targets.mako.enable = false;

    services.mako = {
      enable = true;
      settings = {
        anchor = "top-right";
        group-by = "app-name,summary,body";
        default-timeout = 5000;
        width = 420;
        outer-margin = 20;
        padding = "10,15";
        border-size = 2;
        border-radius = 0;
        max-icon-size = 32;
        font = "JetBrainsMono Nerd Font 14";
        text-color = "#${colors.base05}";
        border-color = "#${colors.base0D}";
        background-color = "#${colors.base00}";
        "mode=do-not-disturb".invisible = true;
        "mode=do-not-disturb app-name=notify-send".invisible = false;
        "mode=do-not-disturb app-name=nixconf-menu".invisible = false;
        "mode=do-not-disturb app-name=nixconf-capture".invisible = false;
        "app-name=nixconf-menu" = {
          anchor = "bottom-center";
          width = 360;
        };
        "urgency=critical" = {
          default-timeout = 0;
          layer = "overlay";
        };
        "summary~='Screenshot saved'" = {
          max-icon-size = 160;
          on-button-left = "invoke-default-action";
          format = "<b>%s</b>\n%b";
        };
        "summary~='Screen recording saved'" = {
          max-icon-size = 160;
          on-button-left = "invoke-default-action";
          format = "<b>%s</b>\n%b";
        };
      };
    };
  };
}
