_: {
  flake.modules.homeManager.base = {pkgs, ...}: let
    sessionPicker = pkgs.writeShellApplication {
      name = "tmux-session-picker";
      runtimeInputs = with pkgs; [sesh fzf tmux zoxide];
      text = ''
        if selection=$(sesh list | fzf --no-sort --layout=reverse \
          --border=none --info=inline --prompt='Session › ' \
          --header='Enter connect · Esc cancel'); then
          if [[ -n "$selection" ]]; then
            sesh connect "$selection"
          fi
        fi
      '';
    };
  in {
    home.packages = [pkgs.sesh];
    programs.tmux = {
      enable = true;
      sensibleOnTop = false;
      terminal = "tmux-256color";
      shell = "${pkgs.zsh}/bin/zsh";
      baseIndex = 1;
      keyMode = "vi";
      customPaneNavigationAndResize = true;
      mouse = true;
      focusEvents = true;
      escapeTime = 10;
      historyLimit = 50000;
      plugins = with pkgs.tmuxPlugins; [
        {
          plugin = tmux-thumbs;
          extraConfig = "set -g @thumbs-osc52 1";
        }
        {
          plugin = resurrect;
          extraConfig = ''
            # Restore layout and directories, never replay arbitrary commands.
            set -g @resurrect-processes 'false'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '15'
          '';
        }
      ];
      extraConfig = ''
        set -g renumber-windows on
        set -g status-position top
        set -g status-interval 5
        set -g status-left-length 40
        set -g status-right-length 60
        set -g window-status-separator ""
        set -g pane-border-lines single

        # Amp: images, hyperlinks, clipboard, and distinct Shift+Enter.
        set -g allow-passthrough all
        set -as terminal-features ",xterm-kitty:RGB:hyperlinks:extkeys"
        set -s set-clipboard on
        set -s extended-keys on
        set -s extended-keys-format csi-u
        bind -n S-Enter send-keys -l "\033[13;2u"

        bind '|' split-window -h -c "#{pane_current_path}"
        bind '-' split-window -v -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"
        # Popups bypass interactive shell hooks, so load the project explicitly.
        bind g display-popup -E -w 90% -h 90% -d "#{pane_current_path}" "${pkgs.direnv}/bin/direnv exec . ${pkgs.lazygit}/bin/lazygit"
        bind t display-popup -E -w 85% -h 80% -d "#{pane_current_path}" "${pkgs.zsh}/bin/zsh"
        bind o display-popup -E -w 70% -h 60% -d "#{pane_current_path}" "${sessionPicker}/bin/tmux-session-picker"

        # smart-splits.nvim marks its pane eagerly; no process-name polling.
        bind -n C-h if -F '#{@pane-is-vim}' 'send-keys C-h' 'select-pane -L'
        bind -n C-j if -F '#{@pane-is-vim}' 'send-keys C-j' 'select-pane -D'
        bind -n C-k if -F '#{@pane-is-vim}' 'send-keys C-k' 'select-pane -U'
        bind -n C-l if -F '#{@pane-is-vim}' 'send-keys C-l' 'select-pane -R'
        bind -n M-h if -F '#{@pane-is-vim}' 'send-keys M-h' 'resize-pane -L 3'
        bind -n M-j if -F '#{@pane-is-vim}' 'send-keys M-j' 'resize-pane -D 3'
        bind -n M-k if -F '#{@pane-is-vim}' 'send-keys M-k' 'resize-pane -U 3'
        bind -n M-l if -F '#{@pane-is-vim}' 'send-keys M-l' 'resize-pane -R 3'
        bind -T copy-mode-vi C-h select-pane -L
        bind -T copy-mode-vi C-j select-pane -D
        bind -T copy-mode-vi C-k select-pane -U
        bind -T copy-mode-vi C-l select-pane -R
        bind -T copy-mode-vi v send-keys -X begin-selection
        bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      '';
    };
  };

  flake.modules.homeManager.desktop = {
    config,
    lib,
    ...
  }: let
    colors = config.lib.stylix.colors;
  in {
    # Stylix supplies the palette; this module owns the status-bar layout.
    stylix.targets.tmux.enable = false;
    # Set status-right before plugins: continuum appends its autosave hook.
    xdg.configFile."tmux/tmux.conf".text = lib.mkBefore ''
      set -g status-style "bg=#${colors.base00},fg=#${colors.base04}"
      set -g status-left "#[bg=#${colors.base0D},fg=#${colors.base00},bold] #S #[default] "
      set -g status-right "#{?pane_in_mode,#[fg=#${colors.base0A}] COPY ,}#{?client_prefix,#[fg=#${colors.base0B}] PREFIX ,}#[fg=#${colors.base04}] #{pane_current_command} · #h "
      set -g window-status-format "#[fg=#${colors.base04}] #I:#W "
      set -g window-status-current-format "#[bg=#${colors.base02},fg=#${colors.base0D},bold] #I:#W #[default]"
      set -g window-status-activity-style "fg=#${colors.base0A}"
      set -g pane-border-style "fg=#${colors.base02}"
      set -g pane-active-border-style "fg=#${colors.base0D}"
      set -g message-style "bg=#${colors.base02},fg=#${colors.base05}"
      set -g mode-style "bg=#${colors.base0D},fg=#${colors.base00}"
      set -g popup-style "bg=#${colors.base00},fg=#${colors.base05}"
      set -g popup-border-style "fg=#${colors.base0D}"
      set -g popup-border-lines single
    '';
  };
}
