_: {
  flake.modules.homeManager.desktop = {
    config,
    lib,
    pkgs,
    ...
  }: {
    home.packages = [(pkgs.discord-canary.override {withVencord = true;})];
    stylix.targets.vencord.enable = false;
    xdg.mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/discord" = ["discord-canary.desktop"];
    };

    home.activation.disableVencordStylix = lib.hm.dag.entryAfter ["writeBoundary"] ''
      settings_dir=${lib.escapeShellArg "${config.xdg.configHome}/Vencord/settings"}
      settings_file="$settings_dir/settings.json"

      if [[ -f "$settings_file" ]]; then
        temporary="$(${pkgs.coreutils}/bin/mktemp "$settings_dir/settings.json.XXXXXX")"
        if ${pkgs.jq}/bin/jq \
          'if .enabledThemes then .enabledThemes -= ["stylix.theme.css"] else . end' \
          "$settings_file" > "$temporary"; then
          if ! ${pkgs.diffutils}/bin/cmp -s "$settings_file" "$temporary"; then
            run mv "$temporary" "$settings_file"
          else
            run rm "$temporary"
          fi
        else
          run rm "$temporary"
          echo "warning: Vencord settings are not valid JSON; leaving them unchanged" >&2
        fi
      fi
    '';
  };
}
