{inputs, ...}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: let
    config = inputs.self.nixosConfigurations.t1.config;
    display = config.services.displayManager;
  in {
    checks = lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      login-theme = assert lib.assertMsg (display.sddm.enable && !config.services.greetd.enable) "Only SDDM should own the login screen";
      assert lib.assertMsg (display.defaultSession == "hyprland-uwsm") "Login must start the UWSM-managed session";
      assert lib.assertMsg (display.autoLogin.enable && display.autoLogin.user == "mvs" && !display.sddm.autoLogin.relogin) "Autologin is only allowed at boot, not after logout";
      assert lib.assertMsg (!(builtins.elem "plymouth-quit.service" config.systemd.services.display-manager.after)) "Display manager must not wait for the desktop-ready Plymouth job";
        pkgs.runCommand "nixconf-login-theme" {
          nativeBuildInputs = [pkgs.qt6.qtdeclarative];
          LANG = "C.UTF-8";
          FONTCONFIG_FILE = pkgs.makeFontsConf {fontDirectories = [pkgs.nerd-fonts.jetbrains-mono];};
          QT_QPA_PLATFORM = "offscreen";
          QT_QUICK_BACKEND = "software";
          QML_IMPORT_PATH = "${pkgs.qt6.qtdeclarative}/lib/qt-6/qml";
        } ''
          export HOME="$TMPDIR"
          export XDG_RUNTIME_DIR="$TMPDIR/runtime"
          mkdir -m 700 "$XDG_RUNTIME_DIR"
          mkdir -p scripts modules/nixos/desktop/sddm
          cp ${../../nixos/desktop/sddm/Main.qml} modules/nixos/desktop/sddm/Main.qml
          cp ${../../../scripts/tst_login_theme.qml} scripts/tst_login_theme.qml
          qmltestrunner -input scripts/tst_login_theme.qml
          touch "$out"
        '';
    };
  };
}
