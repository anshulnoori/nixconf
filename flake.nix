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
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
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
        inputs.git-hooks.flakeModule
      ];

      perSystem = {
        config,
        pkgs,
        ...
      }: let
        # commitizen 4.13.9's test suite fails under Python 3.14 in current
        # nixpkgs (an argparse error-message quoting change). Skip its checks;
        # the tool itself works. Drop this override once nixpkgs is fixed.
        commitizen = pkgs.commitizen.overridePythonAttrs (_: {doCheck = false;});

        branchNameCheck = pkgs.writeShellScript "branch-name-check" ''
          set -eu
          branch="$(git rev-parse --abbrev-ref HEAD)"
          if [ "$branch" = "master" ]; then
            exit 0
          fi
          pattern='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|flake|host|module)/[a-z0-9-]+$'
          if ! printf '%s' "$branch" | grep -qE "$pattern"; then
            echo "Branch name '$branch' does not follow the naming convention." >&2
            echo "Expected: type/short-kebab-description" >&2
            echo "Example:  feat/add-desktop-host" >&2
            exit 1
          fi
        '';
      in {
        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true; # *.nix
            prettier.enable = true; # *.md, *.json, *.yaml/*.yml
            shfmt.enable = true; # *.sh
          };
        };

        pre-commit.settings.hooks = {
          treefmt = {
            enable = true;
            package = config.treefmt.build.wrapper;
          };
          statix.enable = true;
          deadnix.enable = true;
          commitizen = {
            enable = true;
            package = commitizen;
          };
          branch-name = {
            enable = true;
            name = "branch naming convention";
            entry = "${branchNameCheck}";
            stages = ["pre-push"];
            pass_filenames = false;
            always_run = true;
          };
        };

        devShells.default = pkgs.mkShell {
          shellHook = config.pre-commit.installationScript;
          buildInputs = with pkgs; [
            nil
            alejandra
            statix
            deadnix
            commitizen
            cachix
            git
          ];
        };
      };
    };
}
