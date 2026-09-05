_: {
  flake.modules.homeManager.desktop = {
    config,
    lib,
    pkgs,
    ...
  }: let
    version = lib.versions.majorMinor pkgs.blender.version;
    indent = text: "  " + lib.concatStringsSep "\n  " (lib.splitString "\n" text);
  in {
    home.packages = [pkgs.blender];
    stylix.targets.blender.enable = true;

    # The pinned Stylix release predates Blender 5.x, so provide its generated
    # preset at the current version's path as well.
    xdg.configFile."blender/${version}/scripts/presets/interface_theme/Stylix.xml".text = lib.concatLines [
      "<bpy>"
      (indent config.stylix.targets.blender.themeBody)
      "</bpy>"
    ];

    xdg.mimeApps = {
      enable = true;
      defaultApplications."application/x-blender" = ["blender.desktop"];
    };
  };
}
