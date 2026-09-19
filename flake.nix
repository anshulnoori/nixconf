{
  description = "Anshul's personal NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://attic.xuyh0120.win/lantian"
      "https://afnix-hydra.s3-bulk-web.afnix.fr/"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "afnix:oqt801y+IwJ09XRtNDQYCKb7zuCw9DQXQk8fDWPkwxM="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak = {
      url = "github:gmodena/nix-flatpak?ref=latest";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Waybar still requires the workspace IDs removed by Hyprland's
    # September 9 address/type IPC refactor. Keep the compatible locked revision.
    hyprland.url = "github:hyprwm/Hyprland/c1239d02e759673977de0389d3945c7c9adbc1ee";

    waybar = {
      url = "github:Alexays/Waybar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wrappers = {
      url = "github:Lassulus/wrappers";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    namespace-devbox-release = {
      url = "file+https://github.com/namespacelabs/devbox/releases/latest/download/checksums.txt";
      flake = false;
    };

    monorepo = {
      url = "git+ssh://git@github.com/anshulnoori/monorepo.git";
      inputs.namespace-devbox-release.follows = "namespace-devbox-release";
    };

    # Intentional rice snapshot. Do not advance with routine dependency updates.
    omarchy-rice = {
      url = "github:basecamp/omarchy/a7f8f2495f4990044b7791d8f11a32cf14d34b39";
      flake = false;
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lix.follows = "lix";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;}
    (inputs.import-tree ./modules);
}
