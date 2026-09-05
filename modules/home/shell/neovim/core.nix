{inputs, ...}: {
  flake.modules.homeManager.base = {
    lib,
    pkgs,
    ...
  }: {
    imports = [inputs.nvf.homeManagerModules.default];

    programs.nvf = {
      enable = true;
      defaultEditor = true;
      settings.vim = {
        package = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;
        viAlias = true;
        vimAlias = true;

        globals = {
          mapleader = " ";
          maplocalleader = "\\";
          autoformat = true;
          markdown_recommended_style = 0;
        };
        options = {
          autowrite = true;
          breakindent = false;
          completeopt = "menu,menuone,noselect";
          conceallevel = 2;
          confirm = true;
          cursorline = true;
          expandtab = true;
          fillchars = "foldopen:,foldclose:,fold: ,foldsep: ,diff:╱,eob: ";
          foldlevel = 99;
          foldmethod = "indent";
          foldtext = "";
          formatoptions = "jcroqlnt";
          grepformat = "%f:%l:%c:%m";
          grepprg = "rg --vimgrep";
          ignorecase = true;
          inccommand = "nosplit";
          jumpoptions = "view";
          laststatus = 3;
          linebreak = true;
          list = true;
          mouse = "a";
          number = true;
          pumblend = 10;
          pumheight = 10;
          relativenumber = true;
          ruler = false;
          scrolloff = 4;
          sessionoptions = "buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds";
          shada = "!,'100,<50,s10,h";
          shiftround = true;
          shiftwidth = 2;
          showmode = false;
          sidescrolloff = 8;
          signcolumn = "yes";
          smartcase = true;
          smartindent = true;
          smoothscroll = true;
          splitbelow = true;
          splitkeep = "screen";
          splitright = true;
          tabstop = 2;
          termguicolors = true;
          # nvf declares the short name; setting timeoutlen alone loses to tm.
          tm = 300;
          undofile = true;
          undolevels = 10000;
          updatetime = 200;
          virtualedit = "block";
          wildmode = "longest:full,full";
          winminwidth = 5;
          wrap = false;
        };

        extraPackages = [
          pkgs.curl
          pkgs.ripgrep
        ];

        treesitter = {
          enable = true;
          context.enable = true;
        };
        git.gitsigns = {
          enable = true;
          mappings = {
            nextHunk = null;
            previousHunk = null;
            stageHunk = null;
            resetHunk = null;
            undoStageHunk = null;
            stageBuffer = null;
            resetBuffer = null;
            previewHunk = null;
            blameLine = null;
            toggleBlame = null;
            diffThis = null;
            diffProject = null;
            toggleDeleted = null;
          };
          setupOpts = {
            signs = {
              add.text = "▎";
              change.text = "▎";
              delete.text = "";
              topdelete.text = "";
              changedelete.text = "▎";
              untracked.text = "▎";
            };
            signs_staged = {
              add.text = "▎";
              change.text = "▎";
              delete.text = "";
              topdelete.text = "";
              changedelete.text = "▎";
            };
            on_attach = lib.generators.mkLuaInline ''
              function(buffer)
                local gs = require("gitsigns")
                local function map(mode, key, action, desc)
                  vim.keymap.set(mode, key, action, { buffer = buffer, silent = true, desc = desc })
                end
                for key, direction in pairs({ ["]h"] = "next", ["[h"] = "prev", ["]H"] = "last", ["[H"] = "first" }) do
                  map("n", key, function()
                    if vim.wo.diff and (direction == "next" or direction == "prev") then
                      vim.cmd.normal({ direction == "next" and "]c" or "[c", bang = true })
                    else gs.nav_hunk(direction) end
                  end, direction .. " Hunk")
                end
                map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<cr>", "Stage Hunk")
                map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<cr>", "Reset Hunk")
                for key, action in pairs({ ghS = "stage_buffer", ghu = "undo_stage_hunk", ghR = "reset_buffer", ghp = "preview_hunk_inline", ghB = "blame", ghd = "diffthis" }) do
                  map("n", "<leader>" .. key, gs[action], action)
                end
                map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
                map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
                map({ "o", "x" }, "ih", ":<C-u>Gitsigns select_hunk<cr>", "GitSigns Select Hunk")
              end
            '';
          };
        };
        binds.whichKey.enable = true;
        notes.todo-comments.enable = true;
        luaConfigRC.editor-interaction = lib.hm.dag.entryAfter ["mappings"] (builtins.readFile ./core.lua);
      };
    };
  };
}
