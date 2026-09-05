_: {
  flake.modules.homeManager.base = {lib, ...}: let
    inherit (lib.hm.dag) entryBetween;
    inherit (lib.generators) mkLuaInline;
  in {
    programs.nvf.settings.vim = {
      additionalRuntimePaths = [./runtime];
      binds.whichKey = {
        # nvf's modern preset spans most of the screen. The Mac uses helix.
        register = lib.mkForce {};
        setupOpts = {
          preset = "helix";
          replace = lib.mkForce {};
          # Keep the Linux square-border policy, not the Mac's rounded corners.
          win.border = "single";
          spec = mkLuaInline ''
            {
              { mode = { "n", "x" },
                { "<leader><tab>", group = "tabs" },
                { "<leader>c", group = "code" },
                { "<leader>d", group = "debug" },
                { "<leader>dp", group = "profiler" },
                { "<leader>f", group = "file/find" },
                { "<leader>g", group = "git" },
                { "<leader>gh", group = "hunks" },
                { "<leader>G", group = "Gradle" },
                { "<leader>q", group = "quit/session" },
                { "<leader>s", group = "search" },
                { "<leader>sn", group = "noice" },
                { "<leader>t", group = "test" },
                { "<leader>u", group = "ui" },
                { "<leader>x", group = "diagnostics/quickfix" },
                { "[", group = "prev" }, { "]", group = "next" },
                { "g", group = "goto" }, { "z", group = "fold" },
                { "<leader>b", group = "buffer", expand = function()
                  return require("which-key.extras").expand.buf()
                end },
                { "<leader>w", group = "windows", proxy = "<c-w>", expand = function()
                  return require("which-key.extras").expand.win()
                end },
                { "gx", desc = "Open with system app" },
              },
            }
          '';
        };
      };
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
          setupOpts = {
            presets = {
              inc_rename = true;
              bottom_search = true;
              command_palette = true;
              long_message_to_split = true;
            };
            lsp.override = {
              "vim.lsp.util.convert_input_to_markdown_lines" = true;
              "vim.lsp.util.stylize_markdown" = true;
            };
            routes = [
              {
                filter = {
                  event = "msg_show";
                  any = [
                    {find = "%d+L, %d+B";}
                    {find = "; after #%d+";}
                    {find = "; before #%d+";}
                  ];
                };
                view = "mini";
              }
            ];
          };
        };
      };
      tabline.nvimBufferline = {
        enable = true;
        mappings = {
          cycleNext = null;
          cyclePrevious = null;
          pick = null;
          sortByExtension = null;
          sortByDirectory = null;
          sortById = null;
          moveNext = null;
          movePrevious = null;
        };
        setupOpts.options = {
          always_show_bufferline = false;
          numbers = "none";
          indicator.style = "icon";
          diagnostics = "nvim_lsp";
          close_command = mkLuaInline "function(n) Snacks.bufdelete(n) end";
          right_mouse_command = mkLuaInline "function(n) Snacks.bufdelete(n) end";
          offsets = [{filetype = "snacks_layout_box";}];
          diagnostics_indicator = mkLuaInline ''
            function(_, _, diag)
              return vim.trim((diag.error and " " .. diag.error .. " " or "")
                .. (diag.warning and " " .. diag.warning or ""))
            end
          '';
        };
      };
      statusline.lualine = {
        enable = true;
        sectionSeparator = {
          left = "";
          right = "";
        };
        componentSeparator = {
          left = "";
          right = "";
        };
        setupOpts = {
          options = {
            globalstatus = true;
            disabled_filetypes.statusline = ["snacks_dashboard"];
          };
          sections = {
            lualine_a = ["mode"];
            lualine_b = ["branch"];
            lualine_c = [
              (mkLuaInline "require('nixconf.lualine').root_dir")
              (mkLuaInline ''{ "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = " " } }'')
              (mkLuaInline ''{ "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } }'')
              (mkLuaInline "require('nixconf.lualine').pretty_path")
              (mkLuaInline "require('nixconf.lualine').symbols")
            ];
            lualine_x = [
              (mkLuaInline "require('snacks').profiler.status()")
              (mkLuaInline ''
                {
                  function() return require("noice").api.status.command.get() end,
                  cond = function() return package.loaded.noice and require("noice").api.status.command.has() end,
                  color = function() return { fg = Snacks.util.color("Statement") } end,
                }
              '')
              (mkLuaInline ''
                {
                  function() return require("noice").api.status.mode.get() end,
                  cond = function() return package.loaded.noice and require("noice").api.status.mode.has() end,
                  color = function() return { fg = Snacks.util.color("Constant") } end,
                }
              '')
              (mkLuaInline ''
                {
                  function() return "  " .. require("dap").status() end,
                  cond = function() return package.loaded.dap and require("dap").status() ~= "" end,
                  color = function() return { fg = Snacks.util.color("Debug") } end,
                }
              '')
              (mkLuaInline ''
                { "diff",
                  symbols = { added = " ", modified = " ", removed = " " },
                  source = function()
                    local signs = vim.b.gitsigns_status_dict
                    if signs then return { added = signs.added, modified = signs.changed, removed = signs.removed } end
                  end,
                }
              '')
            ];
            lualine_y = [
              (mkLuaInline ''{ "progress", separator = " ", padding = { left = 1, right = 0 } }'')
              (mkLuaInline ''{ "location", padding = { left = 0, right = 1 } }'')
            ];
            lualine_z = [(mkLuaInline ''function() return " " .. os.date("%R") end'')];
          };
        };
      };
    };
  };
}
