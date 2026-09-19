_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    toml = pkgs.formats.toml {};
  in {
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
