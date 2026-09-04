_: {
  flake.modules.homeManager.base.programs.nvf.settings.vim = {
    utility = {
      grug-far-nvim.enable = true;
      motion.flash-nvim.enable = true;
      snacks-nvim = {
        enable = true;
        setupOpts = {
          dashboard = {
            enabled = true;
            sections = [
              {section = "header";}
              {
                section = "keys";
                gap = 1;
                padding = 1;
              }
            ];
          };
          explorer.enabled = true;
          indent.enabled = true;
          input.enabled = true;
          notifier.enabled = true;
          picker.enabled = true;
          quickfile.enabled = true;
          scope.enabled = true;
          scroll.enabled = true;
          statuscolumn.enabled = true;
          words.enabled = true;
        };
      };
    };

    keymaps = [
      {
        key = "<leader>e";
        mode = "n";
        action = "function() Snacks.explorer() end";
        lua = true;
        desc = "File explorer";
      }
      {
        key = "<leader>ff";
        mode = "n";
        action = "function() Snacks.picker.files() end";
        lua = true;
        desc = "Find files";
      }
      {
        key = "<leader>fg";
        mode = "n";
        action = "function() Snacks.picker.grep() end";
        lua = true;
        desc = "Grep files";
      }
      {
        key = "<leader>fr";
        mode = "n";
        action = "function() Snacks.picker.recent() end";
        lua = true;
        desc = "Recent files";
      }
      {
        key = "<leader>gg";
        mode = "n";
        action = "function() Snacks.lazygit() end";
        lua = true;
        desc = "Lazygit";
      }
      {
        key = "<leader>sr";
        mode = "n";
        action = "<cmd>GrugFar<cr>";
        desc = "Search and replace";
      }
    ];
  };
}
