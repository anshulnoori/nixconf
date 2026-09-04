_: {
  flake.modules.homeManager.base.programs.nvf.settings.vim = {
    formatter.conform-nvim = {
      enable = true;
      setupOpts = {
        format_after_save = null;
        format_on_save = {
          lsp_format = "fallback";
          timeout_ms = 3000;
        };
        formatters = {
          alejandra.command = "alejandra";
          biome.command = "biome";
          ocamlformat.command = "ocamlformat";
        };
        formatters_by_ft = {
          astro = ["biome"];
          css = ["biome"];
          graphql = ["biome"];
          html = ["biome"];
          javascript = ["biome"];
          javascriptreact = ["biome"];
          json = ["biome"];
          jsonc = ["biome"];
          nix = ["alejandra"];
          ocaml = ["ocamlformat"];
          ocamlinterface = ["ocamlformat"];
          svelte = ["biome"];
          typescript = ["biome"];
          typescriptreact = ["biome"];
          vue = ["biome"];
        };
      };
    };
    diagnostics.nvim-lint.enable = true;
  };
}
