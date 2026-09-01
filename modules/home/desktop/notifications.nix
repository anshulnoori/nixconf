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
        "urgency=critical" = {
          default-timeout = 0;
          layer = "overlay";
        };
        "summary~='Screenshot saved'" = {
          max-icon-size = 80;
          format = "<b>%s</b>\n%b";
        };
      };
    };
  };
}
