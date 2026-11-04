{inputs, ...}: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    programs.waybar.package = inputs.waybar.packages.${pkgs.stdenv.hostPlatform.system}.waybar.overrideAttrs (old: {
      # The bar has no cava module, and upstream's vendored libcava no longer matches its libcava wrap.
      mesonFlags = (pkgs.lib.remove "-Dcava=enabled" old.mesonFlags) ++ ["-Dcava=disabled"];
      patches = (old.patches or []) ++ [./tray-text.patch ./group-reveal-signal.patch];
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace test/utils/meson.build \
            --replace-fail "'sleeper_thread.cpp'," ""
        '';
    });
  };
}
