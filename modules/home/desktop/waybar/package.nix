{inputs, ...}: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    programs.waybar.package = inputs.waybar.packages.${pkgs.stdenv.hostPlatform.system}.waybar.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./tray-text.patch];
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace test/utils/meson.build \
            --replace-fail "'sleeper_thread.cpp'," ""
        '';
    });
  };
}
