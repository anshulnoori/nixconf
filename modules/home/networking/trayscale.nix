_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home.packages = [pkgs.trayscale];

    xdg.configFile."autostart/nix-trayscale.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Trayscale
      Exec=${pkgs.trayscale}/bin/trayscale --hide-window
      Terminal=false
    '';
  };
}
