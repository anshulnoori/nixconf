_: {
  flake.modules.homeManager.desktop.xdg.configFile."elephant/menus/nixconf-background.lua".text =
    (import ./_wallpapers.nix).menu;
}
