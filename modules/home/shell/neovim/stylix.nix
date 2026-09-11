_: {
  flake.modules.homeManager.desktop = {
    config,
    lib,
    ...
  }: let
    cfg = config.stylix.targets.nvf;
  in {
    # Stylix still writes nvf's deprecated lualine.theme option. Keep its
    # palette integration here until upstream uses setupOpts.options.theme.
    stylix.targets.nvf.enable = false;
    programs.nvf.settings.vim = {
      theme = {
        enable = true;
        name = cfg.plugin;
        transparent = cfg.transparentBackground;
        base16-colors = {
          inherit
            (config.lib.stylix.colors.withHashtag)
            base00
            base01
            base02
            base03
            base04
            base05
            base06
            base07
            base08
            base09
            base0A
            base0B
            base0C
            base0D
            base0E
            base0F
            ;
        };
      };
      statusline.lualine.setupOpts.options.theme = lib.mkIf (cfg.plugin == "base16") "base16";
    };
  };
}
