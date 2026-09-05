{inputs, ...}: {
  flake.modules.homeManager.desktop = {config, ...}: let
    colors = config.lib.stylix.colors;
  in {
    services.walker.theme = {
      name = "Gruvbox Dark";
      layout.layout = builtins.readFile "${inputs.omarchy-rice}/default/walker/themes/omarchy-default/layout.xml";
      style = ''
        @define-color selected-text #${colors.base0D};
        @define-color text #${colors.base05};
        @define-color base #${colors.base00};
        @define-color border #${colors.base05};
        @define-color background #${colors.base00};

        * {
          all: unset;
          font-family: "JetBrainsMono Nerd Font";
          font-size: 18px;
          color: @text;
        }

        scrollbar { opacity: 0; }
        .normal-icons { -gtk-icon-size: 16px; }
        .large-icons { -gtk-icon-size: 32px; }

        .box-wrapper {
          background: alpha(@base, 0.95);
          padding: 20px;
          border: 2px solid @border;
        }

        .search-container {
          background: @base;
          padding: 10px;
        }

        .input placeholder { opacity: 0.5; }
        .input:focus, .input:active {
          box-shadow: none;
          outline: none;
        }

        child:selected { background: alpha(@text, 0.07); }
        child:selected .item-box * { color: @selected-text; }
        .item-box { padding-left: 14px; }
        .item-text-box {
          all: unset;
          padding: 14px 0;
        }
        .item-subtext {
          font-size: 0;
          min-height: 0;
          margin: 0;
          padding: 0;
        }
        .item-image {
          margin-right: 14px;
          -gtk-icon-transform: scale(0.9);
        }
        .current { font-style: italic; }
        .keybind-hints {
          background: @background;
          padding: 10px;
          margin-top: 10px;
        }
      '';
    };
  };
}
