_: {
  flake.modules.homeManager.gaming = {
    config,
    lib,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
    managedSettings = [
      "alpha"
      "background_alpha"
      "background_color"
      "battery_color"
      "cpu_color"
      "cpu_load_color"
      "engine_color"
      "font_scale"
      "font_size"
      "font_size_text"
      "fps_color"
      "frametime_color"
      "gpu_color"
      "gpu_load_color"
      "io_color"
      "media_player_color"
      "text_color"
      "text_outline_color"
      "vram_color"
      "wine_color"
    ];
    managedPattern = lib.concatStringsSep "|" managedSettings;
    stylixSettings = pkgs.writeText "mangohud-stylix.conf" ''
      alpha=${toString config.stylix.opacity.applications}
      background_alpha=${toString config.stylix.opacity.popups}
      background_color=${colors.base00}
      battery_color=${colors.base04}
      cpu_color=${colors.base0D}
      cpu_load_color=${colors.base0B}, ${colors.base0A}, ${colors.base08}
      engine_color=${colors.base0E}
      font_scale=1.33333
      font_size=${toString config.stylix.fonts.sizes.applications}
      font_size_text=${toString config.stylix.fonts.sizes.applications}
      fps_color=${colors.base0B}, ${colors.base0A}, ${colors.base08}
      frametime_color=${colors.base0B}
      gpu_color=${colors.base0B}
      gpu_load_color=${colors.base0B}, ${colors.base0A}, ${colors.base08}
      io_color=${colors.base0A}
      media_player_color=${colors.base05}
      text_color=${colors.base05}
      text_outline_color=${colors.base00}
      vram_color=${colors.base0C}
      wine_color=${colors.base0E}
    '';
  in {
    programs.mangohud.enable = true;
    stylix.targets.mangohud.enable = false;

    home.activation.applyMangoHudStylix = lib.hm.dag.entryAfter ["writeBoundary"] ''
      config_dir=${lib.escapeShellArg "${config.xdg.configHome}/MangoHud"}
      config_file="$config_dir/MangoHud.conf"
      temporary="$config_dir/.MangoHud.conf.new"

      run mkdir -p "$config_dir"
      if [[ -e "$config_file" || -L "$config_file" ]]; then
        ${pkgs.gnused}/bin/sed -E \
          '/^(${managedPattern})[[:space:]]*=/d' \
          "$config_file" > "$temporary"
      else
        : > "$temporary"
      fi
      ${pkgs.coreutils}/bin/cat ${stylixSettings} >> "$temporary"

      if [[ ! -L "$config_file" && -f "$config_file" ]] \
        && ${pkgs.diffutils}/bin/cmp -s "$config_file" "$temporary"; then
        run rm "$temporary"
      else
        run mv "$temporary" "$config_file"
      fi
    '';
  };
}
