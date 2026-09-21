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
            if dispatch == "window.move"
            then builtins.elemAt ["exclam" "at" "numbersign" "dollar" "percent" "asciicircum" "ampersand" "asterisk" "parenleft" "parenright"] index
            else if workspace == 10
            then "0"
            else toString workspace;
        in {
          inherit key;
          desc = description;
          display_group =
            if dispatch == "window.move"
            then "Shift+0…9"
            else "0…9";
          cmd = "hyprctl dispatch 'hl.dsp.${dispatch}({ workspace = ${toString workspace} })'";
        }
      )
      10;
  in {
    programs.wlr-which-key = {
      enable = true;
      package = pkgs.wlr-which-key.overrideAttrs (old: {
        patches = (old.patches or []) ++ [./wlr-which-key-style.patch ./wlr-which-key-single-instance.patch ./wlr-which-key-groups.patch];
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
              key = "j";
              desc = "Apps";
              submenu = [
                {
                  key = "b";
                  desc = "Brave";
                  cmd = "brave-origin";
                }
                {
                  key = "m";
                  desc = "Spotify";
                  cmd = "spotify";
                }
                {
                  key = "s";
                  desc = "Steam";
                  cmd = "steam";
                }
                {
                  key = "y";
                  desc = "Synergy";
                  cmd = "synergy-dragon-gui";
                }
                {
                  key = "d";
                  desc = "Discord";
                  cmd = "DiscordCanary";
                }
                {
                  key = "f";
                  desc = "Files";
                  cmd = "kitty yazi";
                }
                {
                  key = "e";
                  desc = "Neovim";
                  cmd = "kitty nvim";
                }
                {
                  key = "p";
                  desc = "1Password";
                  cmd = "1password";
                }
              ];
            }
            {
              key = "k";
              desc = "Capture";
              submenu = [
                {
                  key = "s";
                  desc = "Screenshot";
                  cmd = "capture-screenshot";
                }
                {
                  key = "r";
                  desc = "Toggle recording";
                  cmd = "if capture-screenrecord active; then capture-screenrecord stop; else walker --width 295 --minheight 1 --maxheight 630 --placeholder 'Record…' --provider menus:nixconf-trigger-capture-screenrecording; fi";
                }
              ];
            }
            {
              key = "i";
              desc = "Toggle keep-awake";
              cmd = "nixconf-toggle caffeine";
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
          ]
          ++ workspaces "focus" "Switch workspace"
          ++ workspaces "window.move" "Move window to workspace";
      };
    };
  };
}
