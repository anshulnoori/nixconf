_: {
  flake.modules.homeManager.desktop = {
    lib,
    pkgs,
    ...
  }: let
    rendered = import ./_render.nix {
      inherit lib;
      icons = import ./_icons.nix;
      tree = import ./_tree.nix;
    };
    launcher = pkgs.writeShellApplication {
      name = "nixconf-menu";
      runtimeInputs = [pkgs.walker];
      text = ''
        exec walker \
          --width 295 \
          --minheight 1 \
          --maxheight 630 \
          --placeholder "Go…" \
          --provider menus:nixconf
      '';
    };
  in {
    home.packages = [launcher];
    xdg.configFile =
      rendered.menuFiles
      // {
        "elephant/menus/nixconf.lua".text = rendered.rootMenu;
      };
  };
}
