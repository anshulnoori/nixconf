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
      utility.yanky-nvim.setupOpts.highlight.timer = 150;
      luaConfigRC.editing = lib.hm.dag.entryAfter ["mappings"] (builtins.readFile ./editing.lua);
      mini = {
        ai = {
          enable = true;
          setupOpts = {
            n_lines = 500;
            custom_textobjects = mkLuaInline ''
              (function()
                local ai = require("mini.ai")
                return {
                  o = ai.gen_spec.treesitter({ a = { "@block.outer", "@conditional.outer", "@loop.outer" }, i = { "@block.inner", "@conditional.inner", "@loop.inner" } }),
                  f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
                  c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
                  t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
                  d = { "%f[%d]%d+" },
                  e = { { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" }, "^().*()$" },
                  g = function(kind)
                    local first, last = 1, vim.fn.line("$")
                    if kind == "i" then
                      first, last = vim.fn.nextnonblank(first), vim.fn.prevnonblank(last)
                      if first == 0 then return { from = { line = 1, col = 1 } } end
                    end
                    return { from = { line = first, col = 1 }, to = { line = last, col = math.max(#vim.fn.getline(last), 1) } }
                  end,
                  u = ai.gen_spec.function_call(),
                  U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
                }
              end)()
            '';
          };
        };
        hipatterns = {
          enable = true;
          setupOpts.highlighters.hex_color =
            mkLuaInline "require('mini.hipatterns').gen_highlighter.hex_color()";
        };
        pairs = {
          enable = true;
          setupOpts.modes = {
            insert = true;
            command = true;
            terminal = false;
          };
        };
      };

      lazy.plugins = {
        flash-nvim.event = "DeferredUIEnter";
        "dial.nvim" = {
          package = pkgs.vimPlugins.dial-nvim;
          event = "DeferredUIEnter";
          after = ''
            local augend = require("dial.augend")
            local groups = {
              default = {
                augend.integer.alias.decimal,
                augend.integer.alias.decimal_int,
                augend.integer.alias.hex,
                augend.date.alias["%Y/%m/%d"],
                augend.constant.alias.en_weekday,
                augend.constant.alias.en_weekday_full,
                augend.constant.new({ elements = { "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth" }, word = false, cyclic = true }),
                augend.constant.new({ elements = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }, word = true, cyclic = true }),
                augend.constant.alias.bool,
                augend.constant.alias.Bool,
                augend.constant.new({ elements = { "&&", "||" }, word = false, cyclic = true }),
              },
              vue = { augend.constant.new({ elements = { "let", "const" } }), augend.hexcolor.new({ case = "lower" }), augend.hexcolor.new({ case = "upper" }) },
              typescript = { augend.constant.new({ elements = { "let", "const" } }) },
              css = { augend.hexcolor.new({ case = "lower" }), augend.hexcolor.new({ case = "upper" }) },
              markdown = { augend.constant.new({ elements = { "[ ]", "[x]" }, word = false, cyclic = true }), augend.misc.alias.markdown_header },
              json = { augend.semver.alias.semver },
              lua = { augend.constant.new({ elements = { "and", "or" }, word = true, cyclic = true }) },
              python = { augend.constant.new({ elements = { "and", "or" } }) },
            }
            for name, group in pairs(groups) do
              if name ~= "default" then vim.list_extend(group, groups.default) end
            end
            require("dial.config").augends:register_group(groups)
            vim.g.dials_by_ft = {
              css = "css", sass = "css", scss = "css", vue = "vue",
              javascript = "typescript", typescript = "typescript",
              typescriptreact = "typescript", javascriptreact = "typescript",
              json = "json", lua = "lua", markdown = "markdown", python = "python",
            }
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
              action = "function() return ':IncRename ' .. vim.fn.expand('<cword>') end";
              lua = true;
              expr = true;
              desc = "Rename symbol";
            }
          ];
        };
      };
    };
  };
}
