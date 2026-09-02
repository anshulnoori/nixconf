_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    packageSearch = pkgs.writeShellApplication {
      name = "nixpkgs-package-search";
      runtimeInputs = [
        pkgs.fzf
        pkgs.jq
        pkgs.nix
        pkgs.nix-search-tv
      ];
      text = ''
        case "''${1:-}" in
          install)
            selection="$(
              nix-search-tv print --indexes nixpkgs |
                fzf --multi \
                  --scheme=history \
                  --preview 'nix-search-tv preview --indexes nixpkgs {}' \
                  --preview-label='alt-p: toggle details, alt-j/k: scroll, tab: multi-select' \
                  --preview-label-pos=bottom \
                  --preview-window='down:65%:wrap' \
                  --bind='alt-p:toggle-preview' \
                  --bind='alt-d:preview-half-page-down,alt-u:preview-half-page-up' \
                  --bind='alt-k:preview-up,alt-j:preview-down' \
                  --color='pointer:green,marker:green'
            )"

            [[ -n "$selection" ]] || exit 0

            installables=()
            while IFS= read -r package; do
              [[ -n "$package" ]] && installables+=("nixpkgs#$package")
            done <<< "$selection"

            nix profile install "''${installables[@]}"
            ;;
          remove)
            profile="$(nix profile list --json)"
            selection="$(
              jq -r '.elements | keys[]' <<< "$profile" |
                fzf \
                  --preview "jq -r --arg name {} '.elements[\$name]' <<< '$profile'" \
                  --preview-window='down:65%:wrap' \
                  --color='pointer:green'
            )"

            [[ -n "$selection" ]] || exit 0
            nix profile remove "$selection"
            ;;
          *)
            printf 'Usage: nixpkgs-package-search <install|remove>\n' >&2
            exit 2
            ;;
        esac
      '';
    };
  in {
    home.packages = [packageSearch];
  };
}
