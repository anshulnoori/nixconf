_: {
  flake.modules.homeManager.base = {lib, ...}: let
    inherit (lib.generators) mkLuaInline;
  in {
    programs.nvf.settings.vim = {
      lsp = {
        enable = true;
        formatOnSave = false;
        inlayHints.enable = true;
        servers = {
          nixd = {
            cmd = ["nixd"];
            filetypes = ["nix"];
            root_markers = [
              ".git"
              "flake.nix"
            ];
          };
          marksman = {
            cmd = [
              "marksman"
              "server"
            ];
            filetypes = ["markdown"];
            root_markers = [
              ".git"
              ".marksman.toml"
            ];
          };
          taplo = {
            cmd = [
              "taplo"
              "lsp"
              "stdio"
            ];
            filetypes = ["toml"];
            root_markers = [
              ".git"
              ".taplo.toml"
              "taplo.toml"
            ];
          };
          yaml-language-server = {
            cmd = [
              "yaml-language-server"
              "--stdio"
            ];
            filetypes = ["yaml"];
            root_markers = [".git"];
            settings.redhat.telemetry.enabled = false;
          };
          vscode-json-language-server = {
            cmd = [
              "vscode-json-language-server"
              "--stdio"
            ];
            filetypes = [
              "json"
              "jsonc"
            ];
            root_markers = [".git"];
            root_dir = mkLuaInline ''
              function(bufnr, on_dir)
                if vim.fs.root(bufnr, { "biome.json", "biome.jsonc" }) then
                  return
                end

                on_dir(vim.fs.root(bufnr, { ".git" }))
              end
            '';
            init_options.provideFormatter = true;
          };
          lua-language-server = {
            cmd = ["lua-language-server"];
            filetypes = ["lua"];
            root_markers = [
              ".git"
              ".luarc.json"
              ".luarc.jsonc"
            ];
          };
          biome = {
            cmd = [
              "biome"
              "lsp-proxy"
            ];
            filetypes = [
              "astro"
              "css"
              "graphql"
              "html"
              "javascript"
              "javascriptreact"
              "json"
              "jsonc"
              "svelte"
              "typescript"
              "typescriptreact"
              "vue"
            ];
            root_markers = [
              "biome.json"
              "biome.jsonc"
            ];
          };
          ocamllsp = {
            cmd = ["ocamllsp"];
            filetypes = [
              "dune"
              "menhir"
              "ocaml"
              "ocamlinterface"
              "ocamllex"
              "reason"
            ];
            root_markers = [
              "dune-project"
              "dune-workspace"
              ".ocamlformat"
            ];
          };
          tailwindcss = {
            cmd = [
              "tailwindcss-language-server"
              "--stdio"
            ];
            filetypes = [
              "astro"
              "css"
              "html"
              "javascript"
              "javascriptreact"
              "svelte"
              "typescript"
              "typescriptreact"
              "vue"
            ];
            root_markers = [
              "tailwind.config.cjs"
              "tailwind.config.js"
              "tailwind.config.mjs"
              "tailwind.config.ts"
              "package.json"
            ];
            handlers."textDocument/publishDiagnostics" = mkLuaInline "function() end";
            settings.tailwindCSS.colorDecorators = true;
          };
        };
      };

      autocmds = [
        {
          event = ["LspAttach"];
          desc = "Render Tailwind colors with Neovim's native LSP support";
          callback = mkLuaInline ''
            function(args)
              local client = vim.lsp.get_client_by_id(args.data.client_id)
              if not client or client.name ~= "tailwindcss" then
                return
              end

              if client:supports_method("textDocument/documentColor", args.buf) then
                vim.lsp.document_color.enable(true, { bufnr = args.buf }, { style = "virtual" })
              end
            end
          '';
        }
      ];
    };
  };
}
