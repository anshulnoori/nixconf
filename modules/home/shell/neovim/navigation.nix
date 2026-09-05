_: {
  flake.modules.homeManager.base = {lib, ...}: {
    programs.nvf.settings.vim = {
      utility = {
        grug-far-nvim.enable = true;
        motion.flash-nvim.enable = true;
        snacks-nvim = {
          enable = true;
          setupOpts = {
            dashboard = {
              enabled = true;
              preset.keys = [
                {
                  icon = " ";
                  key = "f";
                  desc = "Find File";
                  action = ":lua Snacks.picker.files()";
                }
                {
                  icon = " ";
                  key = "n";
                  desc = "New File";
                  action = ":ene | startinsert";
                }
                {
                  icon = " ";
                  key = "p";
                  desc = "Projects";
                  action = ":lua Snacks.picker.projects()";
                }
                {
                  icon = " ";
                  key = "g";
                  desc = "Find Text";
                  action = ":lua Snacks.picker.grep()";
                }
                {
                  icon = " ";
                  key = "r";
                  desc = "Recent Files";
                  action = ":lua Snacks.picker.recent()";
                }
                {
                  icon = " ";
                  key = "c";
                  desc = "Config";
                  action = ":lua Snacks.picker.files({cwd = '/etc/nixos'})";
                }
                {
                  icon = " ";
                  key = "s";
                  desc = "Restore Session";
                  action = ":lua require('persistence').load()";
                }
                {
                  icon = " ";
                  key = "q";
                  desc = "Quit";
                  action = ":qa";
                }
              ];
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
            bigfile.enabled = true;
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

      luaConfigRC.navigation = lib.hm.dag.entryAfter ["mappings"] (builtins.readFile ./navigation.lua);
    };
  };
}
