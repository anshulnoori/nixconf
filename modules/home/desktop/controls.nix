_: {
  flake.modules.homeManager.desktop = {
    config,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
    swayosdStyle = pkgs.writeText "swayosd-gruvbox.css" ''
      window {
        border-radius: 0;
        opacity: 0.97;
        border: 2px solid #${colors.base05};
        background-color: #${colors.base00};
      }

      label {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 11pt;
        color: #${colors.base05};
      }

      image { color: #${colors.base05}; }
      progressbar { border-radius: 0; }
      progress { background-color: #${colors.base0D}; }
    '';
  in {
    services = {
      hyprpolkitagent.enable = true;
      swayosd = {
        enable = true;
        stylePath = swayosdStyle;
      };
    };

    xdg.configFile."swayosd/config.toml".text = ''
      [server]
      show_percentage = true
      max_volume = 100
    '';

    home.packages = with pkgs; [
      bluetui
      brightnessctl
      btop
      impala
      playerctl
      wiremix
    ];
  };
}
