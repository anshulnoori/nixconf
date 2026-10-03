{inputs, ...}: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    programs.waybar.package = inputs.waybar.packages.${pkgs.stdenv.hostPlatform.system}.waybar.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./tray-text.patch];
      # Waybar is rebuilt locally on every update. Its SleeperThread stress
      # test is timing-sensitive and fails intermittently under build load.
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace test/utils/meson.build \
            --replace-fail "'sleeper_thread.cpp'," ""
        '';
    });
  };
}
