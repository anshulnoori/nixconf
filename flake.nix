{
  description = "Anshul's personal NixOS configuration";

  nixConfig = {
    extra-substituters = ["https://anshulnoori.cachix.org"];
    extra-trusted-public-keys = [
      "anshulnoori.cachix.org-1:jzLsepTKLr8/jDh8WdI4uhyimUTDSmxN5ispn1uN/Q0="
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

        ampCliRelease = {
          version = "0.0.1788134497-gb6ce09";
          sources = {
            aarch64-darwin = {
              platform = "darwin-arm64";
              hash = "sha256-TEm+ao9++nsGmQ7D/4q7AWDPKLoDPoyRSrcSm8/731o=";
            };
            x86_64-linux = {
              platform = "linux-x64-baseline";
              hash = "sha256-ZwoZF9xl93hVEtC2fygcE9ccvJMPZJt0Ih+zmec9w7w=";
            };
          };
        };
        ampCliSource = ampCliRelease.sources.${pkgs.stdenv.hostPlatform.system};
        ampCli = pkgs.amp-cli.overrideAttrs (_: {
          inherit (ampCliRelease) version;
          src = pkgs.fetchurl {
            url = "https://static.ampcode.com/cli/${ampCliRelease.version}/amp-${ampCliSource.platform}.gz";
            inherit (ampCliSource) hash;
          };
        });
        installerShell = pkgs.mkShellNoCC {
          packages = with pkgs; [
            ampCli
            git
            tmux
            rsync
            curl
            jq
            less
            gnugrep
            ripgrep
            bat
            openssh
            iproute2
            iputils
            ethtool
            kmod
            util-linux
            pciutils
            usbutils
            dmidecode
            smartmontools
            nvme-cli
            fwupd
            lm_sensors
          ];
        };

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
        packages.amp-cli = ampCli;

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

        devShells =
          {
            default = pkgs.mkShell {
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
          }
          // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
            installer = installerShell;
          };
      };
    };
}
