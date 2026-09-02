_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home = {
      pointerCursor = {
        enable = true;
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
        size = 24;
        gtk.enable = true;
      };
      sessionVariables.HYPRCURSOR_SIZE = "24";
    };

    wayland.windowManager.hyprland.extraConfig = ''
      hl.config({
        cursor = {
          hide_on_key_press = true,
          warp_on_change_workspace = 1,
        },
      })
    '';
  };
}
