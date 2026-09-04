_: {
  flake.modules.homeManager.base = {lib, ...}: let
    inherit (lib.hm.dag) entryBetween;
  in {
    programs.nvf.settings.vim = {
      mini.icons.enable = true;
      visuals.nvim-web-devicons.enable = lib.mkForce false;
      pluginRC.mini-icons-compat = entryBetween ["nvimBufferline"] ["mini-icons"] ''
        require("mini.icons").mock_nvim_web_devicons()
      '';

      ui = {
        borders = {
          enable = true;
          globalStyle = "single";
        };
        noice = {
          enable = true;
          setupOpts.presets.inc_rename = true;
        };
      };
      tabline.nvimBufferline.enable = true;
      statusline.lualine.enable = true;
    };
  };
}
