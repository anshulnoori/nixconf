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
      sessionVariables = {
        HYPRCURSOR_THEME = "rose-pine-hyprcursor";
        HYPRCURSOR_SIZE = "24";
      };
    };

    xdg.dataFile."icons/rose-pine-hyprcursor".source = "${pkgs.rose-pine-hyprcursor}/share/icons/rose-pine-hyprcursor";

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
