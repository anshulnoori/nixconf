{
  description = "Anshul's personal NixOS configuration";

  nixConfig = {
    extra-substituters = ["https://anshulnoori.cachix.org"];
    extra-trusted-public-keys = [
      # TODO: replace with the real key printed by `cachix use anshulnoori`
      "anshulnoori.cachix.org-1:REPLACE_ME"
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      perSystem = _: {
        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true; # *.nix
            prettier.enable = true; # *.md, *.json, *.yaml/*.yml
            shfmt.enable = true; # *.sh
          };
        };
      };
    };
}
