_: {
  flake.modules.homeManager.desktop = {
    config,
    osConfig,
    pkgs,
    ...
  }: let
    toml = pkgs.formats.toml {};
  in {
    home.packages = [pkgs.wl-clipboard];

    systemd.user.services.elephant.Unit.X-Restart-Triggers = [
      config.home.path
      osConfig.system.path
    ];

    services.elephant = {
      enable = true;
      settings.providers.default = [
        "desktopapplications"
        "files"
        "clipboard"
        "symbols"
        "calc"
        "websearch"
        "providerlist"
      ];
    };

    xdg.configFile = {
      "elephant/calc.toml".source = toml.generate "elephant-calc.toml" {
        async = false;
      };
      "elephant/desktopapplications.toml".source = toml.generate "elephant-desktopapplications.toml" {
        show_actions = false;
        only_search_title = true;
        history = false;
      };
      "elephant/symbols.toml".source = toml.generate "elephant-symbols.toml" {
        command = "wl-copy";
      };
    };
  };
}
