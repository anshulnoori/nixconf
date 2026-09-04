_: {
  flake.modules.homeManager.base = {
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.generators) mkLuaInline;
    minuetApiKey = mkLuaInline ''
      (function()
        local token

        return function()
          if token then
            return token
          end

          local op = vim.fn.exepath("op")
          if op == "" then
            vim.notify_once("Minuet: 1Password CLI is unavailable", vim.log.levels.WARN)
            return nil
          end

          local result = vim.system({
            op,
            "item",
            "get",
            "dt3oxa4uin5steqpm6v266jrma",
            "--fields",
            "label=credential",
            "--reveal",
          }, { text = true }):wait()

          if result.code ~= 0 then
            vim.notify_once("Minuet: unlock 1Password to load the API token", vim.log.levels.WARN)
            return nil
          end

          local value = vim.trim(result.stdout or "")
          if value == "" then
            vim.notify_once("Minuet: the 1Password credential field is empty", vim.log.levels.WARN)
            return nil
          end

          token = value
          return token
        end
      end)()
    '';
  in {
    programs.nvf.settings.vim = {
      autocomplete.blink-cmp.setupOpts = {
        keymap."<A-y>" = [
          (mkLuaInline "require('minuet').make_blink_map()")
        ];
        sources.providers.minuet = {
          name = "minuet";
          module = "minuet.blink";
          async = true;
          timeout_ms = 3000;
          score_offset = 50;
        };
      };

      lazy.plugins."minuet-ai.nvim" = {
        package = pkgs.vimPlugins.minuet-ai-nvim;
        event = "InsertEnter";
        setupModule = "minuet";
        setupOpts = {
          provider = "openai_compatible";
          debounce = 300;
          throttle = 1000;
          request_timeout = 3;
          blink.enable_auto_complete = false;
          lsp = {
            enabled_ft = [];
            completion.enable = false;
            inline_completion.enable = false;
          };
          virtualtext = {
            auto_trigger_ft = ["*"];
            auto_trigger_ignore_ft = [];
            show_on_completion_menu = false;
          };
          provider_options.openai_compatible = {
            name = "Mongoose Silverside";
            end_point = "https://ai.mongoose-silverside.ts.net/v1/chat/completions";
            model = "deepseek/deepseek-v4-flash";
            stream = true;
            api_key = minuetApiKey;
          };
        };
      };
    };
  };
}
