{moduleWithSystem, ...}: {
  flake.modules.homeManager.base = moduleWithSystem (
    {config, ...}: {
      lib,
      pkgs,
      ...
    }: let
      inherit (lib.generators) mkLuaInline;
      minuetCurl = config.packages.minuet-curl;
    in {
      programs.nvf.settings.vim = {
        autocomplete.blink-cmp.setupOpts = {
          keymap."<A-y>" = [
            (mkLuaInline "require('minuet').make_blink_map()[1]")
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
            curl_cmd = lib.getExe minuetCurl;
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
              api_key = mkLuaInline ''(function() return "${minuetCurl.placeholder}" end)'';
            };
          };
        };
      };
    }
  );
}
