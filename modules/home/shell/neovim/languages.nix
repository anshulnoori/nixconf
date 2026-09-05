_: {
  flake.modules.homeManager.base.programs.nvf.settings.vim = {
    languages = {
      enableDAP = false;
      enableExtraDiagnostics = false;
      enableFormat = false;
      enableTreesitter = true;

      nix = {
        enable = true;
        format.enable = false;
        lsp.enable = false;
      };
      markdown = {
        enable = true;
        lsp.enable = false;
        extensions.render-markdown-nvim.enable = true;
      };
      css = {
        enable = true;
        lsp.enable = false;
      };
      html = {
        enable = true;
        lsp.enable = false;
      };
      java = {
        enable = true;
        dap.enable = false;
        format.enable = false;
        lsp.enable = false;
      };
      ocaml = {
        enable = true;
        format.enable = false;
        lsp.enable = false;
      };
      python = {
        enable = true;
        dap.enable = false;
        format.enable = false;
        lsp.enable = false;
      };
      tex = {
        enable = true;
        format.enable = false;
        lsp.enable = false;
      };
      tsx = {
        enable = true;
        format.enable = false;
        lsp.enable = false;
      };
      typescript = {
        enable = true;
        extraDiagnostics.enable = false;
        format.enable = false;
        lsp.enable = false;
      };
      toml = {
        enable = true;
        lsp.enable = false;
      };
      yaml = {
        enable = true;
        lsp.enable = false;
      };
      json = {
        enable = true;
        lsp.enable = false;
      };
      lua = {
        enable = true;
        lsp.enable = false;
      };
    };

    filetype = {
      filename = {
        ".babelrc" = "json";
        ".editorconfig" = "editorconfig";
        ".env" = "sh";
        ".eslintrc" = "json";
        ".gitconfig" = "gitconfig";
        ".gitignore" = "gitignore";
        ".npmrc" = "dosini";
        ".prettierrc" = "json";
      };
      pattern.".*%.env%..*" = "sh";
    };
  };
}
