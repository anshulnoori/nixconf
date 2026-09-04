_: {
  flake.modules.homeManager.desktop.programs.kitty = {
    enable = true;
    keybindings = {
      "ctrl+insert" = "copy_to_clipboard";
      "shift+insert" = "paste_from_clipboard";
    };
    settings = {
      font_size = 9;
      window_padding_width = 14;
      hide_window_decorations = "yes";
      cursor_shape = "block";
      cursor_blink_interval = 0;
      enable_audio_bell = false;
      confirm_os_window_close = 0;
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
    };
  };
}
