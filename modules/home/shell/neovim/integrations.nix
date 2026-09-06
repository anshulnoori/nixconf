_: {
  flake.modules.homeManager.base = {
    pkgs,
    lib,
    ...
  }: {
    programs.nvf.settings.vim = {
      # Load smart-splits directly at startup, not through lz.n. Its startup
      # hook must run once so it does not mistake itself for nested Neovim.
      # VimTeX must also load at startup for inverse search, while TeXpresso's
      # filetype hook attaches live, unsaved buffer changes to its renderer.
      startPlugins = [
        pkgs.vimPlugins.nvim-nio
        pkgs.vimPlugins.smart-splits-nvim
        pkgs.vimPlugins.texpresso-vim
        pkgs.vimPlugins.vimtex
      ];
      extraPackages = [
        pkgs.texlab
        pkgs.texliveMedium
        pkgs.texpresso
        pkgs.tmux
      ];
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
      luaConfigRC.latex-preview = lib.hm.dag.entryAfter ["tmux-navigation"] ''
        vim.api.nvim_create_autocmd("FileType", {
          pattern = "tex",
          callback = function(args)
            local function map(key, action, desc)
              vim.keymap.set("n", key, action, { buffer = args.buf, silent = true, desc = desc })
            end

            map("<leader>lp", function()
              local root = vim.b.vimtex and vim.b.vimtex.tex or vim.api.nvim_buf_get_name(args.buf)
              vim.cmd("TeXpresso " .. vim.fn.fnameescape(root))
            end, "LaTeX live preview")
            map("<leader>lP", require("texpresso").synctex_forward, "LaTeX preview current position")
            map("<leader>lq", require("texpresso").stop, "LaTeX stop live preview")
          end,
        })
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
      };
    };
  };
}
