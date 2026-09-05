_: {
  flake.modules.homeManager.base = {
    pkgs,
    lib,
    ...
  }: {
    programs.nvf.settings.vim = {
      # Load smart-splits directly at startup, not through lz.n. Its startup
      # hook must run once so it does not mistake itself for nested Neovim.
      startPlugins = [pkgs.vimPlugins.nvim-nio pkgs.vimPlugins.smart-splits-nvim];
      extraPackages = [pkgs.tmux];
      # Extend the editor's window navigation after its generic keymaps load.
      luaConfigRC.tmux-navigation = lib.hm.dag.entryAfter ["editor-interaction"] ''
        for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
          vim.keymap.set("n", "<C-" .. key .. ">", function()
            require("smart-splits")["move_cursor_" .. direction]()
          end, { silent = true, desc = "Focus split " .. direction })
          vim.keymap.set("n", "<C-A-" .. key .. ">", function()
            require("smart-splits")["resize_" .. direction]()
          end, { silent = true, desc = "Resize split " .. direction })
        end
      '';
      lazy.plugins = {
        "amp.nvim" = {
          package = pkgs.vimPlugins.amp-nvim;
          event = "DeferredUIEnter";
          setupModule = "amp";
          setupOpts = {
            auto_start = true;
            log_level = "info";
          };
        };

        gradle-nvim = {
          package = "gradle-nvim";
          cmd = [
            "Gradle"
            "GradleExec"
            "GradleFavorites"
            "GradleInit"
          ];
          setupModule = "gradle";
          setupOpts.gradle_executable = "gradle";
        };

        "uv.nvim" = {
          package = pkgs.vimPlugins.uv-nvim.overrideAttrs {
            runtimeDeps = [];
          };
          event = "DeferredUIEnter";
          setupModule = "uv";
          setupOpts.picker_integration = true;
        };

        vimtex = {
          package = pkgs.vimPlugins.vimtex;
          ft = [
            "plaintex"
            "tex"
          ];
        };
      };
    };
  };
}
