_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    terminalSession = pkgs.writeShellScript "terminal-session" ''
      if [ -n "''${TMUX:-}" ]; then
        exec ${pkgs.zsh}/bin/zsh
      fi
      if ${pkgs.tmux}/bin/tmux has-session 2>/dev/null; then
        exec ${pkgs.tmux}/bin/tmux attach-session
      fi
      exec ${pkgs.tmux}/bin/tmux new-session
    '';
  in {
    programs.kitty = {
      enable = true;
      keybindings = {
        "ctrl+insert" = "copy_to_clipboard";
        "shift+insert" = "paste_from_clipboard";
      };
      settings = {
        shell = "${terminalSession}";
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
  };
}
