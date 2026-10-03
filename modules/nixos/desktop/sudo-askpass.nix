_: {
  flake.modules.nixos.desktop = {
    config,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
    # Same look as the polkit prompt in modules/home/desktop/hyprpolkitagent.nix.
    dialog = pkgs.replaceVars ./sudo-askpass.qml {
      fontFamily = config.stylix.fonts.monospace.name;
      background = "#${colors.base00}";
      field = "#${colors.base01}";
      muted = "#${colors.base03}";
      text = "#${colors.base05}";
      border = "#${colors.base0D}";
    };
    python = pkgs.python3.withPackages (ps: [ps.pyside6]);
    askpass = pkgs.writeShellApplication {
      name = "sudo-askpass";
      text = ''
        export SUDO_ASKPASS_QML=${dialog}
        export QML_IMPORT_PATH=${pkgs.qt6.qtdeclarative}/lib/qt-6/qml
        export QT_PLUGIN_PATH=${pkgs.qt6.qtwayland}/lib/qt-6/plugins:${pkgs.qt6.qtbase}/lib/qt-6/plugins
        export QT_QPA_PLATFORM=wayland
        exec ${python}/bin/python3 ${./sudo-askpass.py} "$@"
      '';
    };
  in {
    # sudo without a terminal (for example from an agent or a launcher) asks
    # through this prompt instead of failing. Terminal sudo is unchanged.
    environment.etc."sudo.conf".text = ''
      Path askpass ${askpass}/bin/sudo-askpass
    '';
  };
}
