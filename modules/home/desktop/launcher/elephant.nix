_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home.packages = [pkgs.wl-clipboard];

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
      "elephant/calc.toml".text = ''
        async = false
      '';
      "elephant/desktopapplications.toml".text = ''
        show_actions = false
        only_search_title = true
        history = false
      '';
      "elephant/symbols.toml".text = ''
        command = "wl-copy"
      '';
    };
  };
}
