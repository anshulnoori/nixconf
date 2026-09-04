_: {
  flake.modules.homeManager.base = {
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.generators) mkLuaInline;
  in {
    programs.nvf.settings.vim = {
      utility.yanky-nvim.enable = true;
      mini = {
        ai.enable = true;
        hipatterns = {
          enable = true;
          setupOpts.highlighters.hex_color =
            mkLuaInline "require('mini.hipatterns').gen_highlighter.hex_color()";
        };
        pairs.enable = true;
      };

      lazy.plugins = {
        "dial.nvim" = {
          package = pkgs.vimPlugins.dial-nvim;
          event = "DeferredUIEnter";
          after = ''
            local augend = require("dial.augend")
            require("dial.config").augends:register_group({
              default = {
                augend.integer.alias.decimal,
                augend.integer.alias.hex,
                augend.date.alias["%Y/%m/%d"],
                augend.constant.alias.bool,
                augend.constant.new({ elements = { "and", "or" } }),
              },
            })
          '';
        };

        "inc-rename.nvim" = {
          package = pkgs.vimPlugins.inc-rename-nvim;
          cmd = "IncRename";
          setupModule = "inc_rename";
          keys = [
            {
              key = "<leader>cr";
              mode = "n";
              action = ":IncRename ";
              desc = "Rename symbol";
            }
          ];
        };
      };
    };
  };
}
