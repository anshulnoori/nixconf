_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    programs.nvf.settings.vim = {
      debugger.nvim-dap = {
        enable = true;
        ui.enable = true;
      };
      utility.preview.markdownPreview.enable = true;

      lazy.plugins = {
        neotest = {
          package = pkgs.vimPlugins.neotest;
          setupModule = "neotest";
          keys = [
            {
              key = "<leader>tt";
              mode = "n";
              action = "function() require('neotest').run.run() end";
              lua = true;
              desc = "Run nearest test";
            }
            {
              key = "<leader>tT";
              mode = "n";
              action = "function() require('neotest').run.run(vim.fn.expand('%')) end";
              lua = true;
              desc = "Run test file";
            }
            {
              key = "<leader>ts";
              mode = "n";
              action = "function() require('neotest').summary.toggle() end";
              lua = true;
              desc = "Toggle test summary";
            }
          ];
        };

        "persistence.nvim" = {
          package = pkgs.vimPlugins.persistence-nvim;
          event = "BufReadPre";
          setupModule = "persistence";
          keys = [
            {
              key = "<leader>qs";
              mode = "n";
              action = "function() require('persistence').load() end";
              lua = true;
              desc = "Restore session";
            }
          ];
        };

        vim-startuptime = {
          package = pkgs.vimPlugins.vim-startuptime;
          cmd = "StartupTime";
        };
      };
    };
  };
}
