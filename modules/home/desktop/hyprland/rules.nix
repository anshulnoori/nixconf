_: {
  flake.modules.homeManager.desktop.wayland.windowManager.hyprland.settings = {
    window_rule = [
      {
        match.class = ".*";
        opacity = 0.97;
      }
      {
        match.class = "kitty";
        opacity = 0.93;
      }
      {
        match.title = "^(Open|Save) (File|Folder)$";
        float = true;
        center = 1;
      }
      {
        match.title = "^Picture in picture$";
        float = true;
        pin = true;
        keep_aspect_ratio = true;
      }
      {
        match.modal = true;
        stay_focused = true;
      }
      {
        match.class = "^hyprpolkitagent$";
        stay_focused = true;
      }
      {
        match.class = "^gcr-prompter$";
        stay_focused = true;
      }
      {
        match = {
          class = "^1password$";
          float = true;
        };
        stay_focused = true;
      }
    ];
    layer_rule = [
      {
        match.namespace = "walker";
        no_anim = true;
        animation = "none";
      }
      {
        match.namespace = "wlr_which_key";
        no_anim = true;
        animation = "none";
      }
    ];
  };
}
