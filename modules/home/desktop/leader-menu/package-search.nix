_: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    nixpkgsPackageSearch = pkgs.writeShellApplication {
      name = "nixpkgs-package-search";
      runtimeInputs = [
        pkgs.fzf
        pkgs.nix-search-tv
      ];
      text = ''
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
      '';
    };
  in {
    home.packages = [nixpkgsPackageSearch];
  };
}
