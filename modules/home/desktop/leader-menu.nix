_: {
  flake.modules.homeManager.desktop = {
    config,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
    workspaces = dispatch: description:
      builtins.genList (
        index: let
          workspace = index + 1;
          key =
            if workspace == 10
            then "0"
            else toString workspace;
        in {
          inherit key;
          desc = "${description} workspace ${toString workspace}";
          cmd = "hyprctl dispatch 'hl.dsp.${dispatch}({ workspace = ${toString workspace} })'";
        }
      )
      10;
  in {
    programs.wlr-which-key = {
      enable = true;
      package = pkgs.wlr-which-key.overrideAttrs (old: {
        patches = (old.patches or []) ++ [./wlr-which-key-style.patch];
        preCheck =
          (old.preCheck or "")
          + ''
            export FONTCONFIG_FILE=${pkgs.makeFontsConf {fontDirectories = [pkgs.dejavu_fonts];}}
            export XDG_CACHE_HOME="$TMPDIR/font-cache"
          '';
      });
      settings = {
        font = "JetBrainsMono Nerd Font 9";
        background = "#${colors.base00}";
        color = "#${colors.base05}";
        key_color = "#${colors.base0D}";
        desc_color = "#${colors.base05}";
        group_color = "#${colors.base0E}";
        separator_color = "#${colors.base03}";
        show_breadcrumbs = true;
        breadcrumb_root = "Desktop";
        row_height = 16;
        border = "#${colors.base05}";
        separator = " ➜ ";
        border_width = 2;
        corner_r = 0;
        padding = 8;
        rows_per_column = 24;
        column_padding = 24;
        anchor = "bottom-right";
        margin_right = 10;
        margin_bottom = 10;
        menu =
          [
            {
              key = "space";
              desc = "Open applications";
              cmd = "walker";
            }
            {
              key = "Alt+space";
              desc = "Open desktop menu";
              cmd = "nixconf-menu";
            }
            {
              key = "Return";
              desc = "Open terminal";
              desc_color = "#${colors.base0B}";
              cmd = "kitty";
            }
            {
              key = "w";
              desc = "Close window";
              cmd = "hyprctl dispatch 'hl.dsp.window.close()'";
            }
            {
              key = "l";
              desc = "Lock";
              desc_color = "#${colors.base0A}";
              cmd = "hyprlock";
            }
            {
              key = "m";
              desc = "Exit desktop";
              desc_color = "#${colors.base08}";
              cmd = "uwsm stop";
            }
            {
              key = "p";
              desc = "Screenshot";
              cmd = "capture-screenshot";
            }
            {
              key = "Left";
              desc = "Focus left";
              cmd = "hyprctl dispatch 'hl.dsp.focus({ direction = \"left\" })'";
            }
            {
              key = "Right";
              desc = "Focus right";
              cmd = "hyprctl dispatch 'hl.dsp.focus({ direction = \"right\" })'";
            }
            {
              key = "Up";
              desc = "Focus up";
              cmd = "hyprctl dispatch 'hl.dsp.focus({ direction = \"up\" })'";
            }
            {
              key = "Down";
              desc = "Focus down";
              cmd = "hyprctl dispatch 'hl.dsp.focus({ direction = \"down\" })'";
            }
            {
              key = "s";
              desc = "Send window to workspace";
              submenu = workspaces "window.move" "Move to";
            }
          ]
          ++ workspaces "focus" "Open";
      };
    };
  };
}
