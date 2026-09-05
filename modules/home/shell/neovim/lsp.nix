_: {
  flake.modules.homeManager.base = {lib, ...}: let
    inherit (lib.generators) mkLuaInline;
  in {
    programs.nvf.settings.vim = {
      diagnostics = {
        enable = true;
        config = {
          underline = true;
          update_in_insert = false;
          severity_sort = true;
          virtual_text = {
            spacing = 4;
            source = "if_many";
            prefix = "●";
          };
          signs.text = mkLuaInline ''{ [1] = " ", [2] = " ", [3] = " ", [4] = " " }'';
        };
      };
      lsp = {
        enable = true;
        trouble = {
          enable = true;
          setupOpts.modes.lsp.win.position = "right";
          mappings = {
            workspaceDiagnostics = null;
            documentDiagnostics = null;
            lspReferences = null;
            quickfix = null;
            locList = null;
            symbols = null;
          };
        };
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
          desc = "Mac reference LSP navigation and code actions";
          callback = mkLuaInline ''
            function(args)
              local function map(key, action, desc, mode)
                vim.keymap.set(mode or "n", key, action, { buffer = args.buf, silent = true, desc = desc })
              end
              for key, source in pairs({ gd = "lsp_definitions", gr = "lsp_references", gI = "lsp_implementations",
                gy = "lsp_type_definitions", ["<leader>ss"] = "lsp_symbols", ["<leader>sS"] = "lsp_workspace_symbols",
                gai = "lsp_incoming_calls", gao = "lsp_outgoing_calls" }) do
                map(key, function() Snacks.picker[source]() end, source)
              end
              map("gD", vim.lsp.buf.declaration, "Goto Declaration")
              map("K", vim.lsp.buf.hover, "Hover")
              map("gK", vim.lsp.buf.signature_help, "Signature Help")
              map("<C-k>", vim.lsp.buf.signature_help, "Signature Help", "i")
              map("<leader>ca", vim.lsp.buf.code_action, "Code Action", { "n", "x" })
            end
          '';
        }
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
