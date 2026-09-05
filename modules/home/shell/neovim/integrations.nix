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
      keymaps =
        lib.concatMap (binding: [
          {
            key = "<C-${binding.key}>";
            mode = "n";
            action = "function() require('smart-splits').move_cursor_${binding.direction}() end";
            lua = true;
            desc = "Focus split ${binding.direction}";
          }
          {
            key = "<A-${binding.key}>";
            mode = "n";
            action = "function() require('smart-splits').resize_${binding.direction}() end";
            lua = true;
            desc = "Resize split ${binding.direction}";
          }
        ]) [
          {
            key = "h";
            direction = "left";
          }
          {
            key = "j";
            direction = "down";
          }
          {
            key = "k";
            direction = "up";
          }
          {
            key = "l";
            direction = "right";
          }
        ];
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
          ft = "python";
          setupModule = "uv";
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
