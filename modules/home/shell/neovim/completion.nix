_: {
  flake.modules.homeManager.base = {lib, ...}: {
    programs.nvf.settings.vim.autocomplete.blink-cmp = {
      enable = true;
      # Disable nvf's Tab/select-next overrides; the reference uses Enter acceptance.
      mappings = {
        complete = null;
        close = null;
        scrollDocsUp = null;
        scrollDocsDown = null;
        confirm = null;
        next = null;
        previous = null;
      };
      setupOpts = {
        keymap = {
          preset = "enter";
          "<C-y>" = ["select_and_accept"];
          "<Tab>" = ["snippet_forward" "fallback"];
        };
        appearance.nerd_font_variant = "mono";
        completion = {
          trigger.prefetch_on_insert = false;
          accept.auto_brackets.enabled = true;
          menu.draw.treesitter = ["lsp"];
          documentation = {
            auto_show = true;
            auto_show_delay_ms = 200;
          };
          ghost_text.enabled = true;
        };
        cmdline = {
          enabled = true;
          keymap = {
            preset = "cmdline";
            "<Right>" = [];
            "<Left>" = [];
          };
          completion = {
            list.selection.preselect = false;
            menu.auto_show = lib.generators.mkLuaInline ''function() return vim.fn.getcmdtype() == ":" end'';
            ghost_text.enabled = true;
          };
        };
      };
    };
  };
}
