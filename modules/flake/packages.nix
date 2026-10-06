{lib, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    commitizen = pkgs.commitizen.overridePythonAttrs (_: {doCheck = false;});

    branchNameCheck = pkgs.writeShellApplication {
      name = "check-branch-name";
      runtimeInputs = [pkgs.gitMinimal];
      text = builtins.readFile ../../scripts/check-branch-name.sh;
    };

    ampCliRelease = {
      version = "0.0.1788134497-gb6ce09";
      source = {
        platform = "linux-x64-baseline";
        hash = "sha256-ZwoZF9xl93hVEtC2fygcE9ccvJMPZJt0Ih+zmec9w7w=";
      };
    };

    ampCliArchive = pkgs.fetchurl {
      url = "https://static.ampcode.com/cli/${ampCliRelease.version}/amp-${ampCliRelease.source.platform}.gz";
      inherit (ampCliRelease.source) hash;
    };

    ampCli = pkgs.writeShellApplication {
      name = "amp";
      runtimeInputs = [pkgs.coreutils pkgs.gzip pkgs.ripgrep pkgs.util-linux];
      text = ''
        export AMP_HOME="''${AMP_HOME:-$HOME/.amp}"
        bin_dir="$AMP_HOME/bin"
        mkdir -p "$bin_dir"

        (
          flock 9
          if [[ ! -e "$bin_dir/amp" ]]; then
            temporary=$(mktemp "$bin_dir/.amp-bootstrap.XXXXXX")
            trap 'rm -f "$temporary"' EXIT
            gzip -dc ${ampCliArchive} > "$temporary"
            chmod 0755 "$temporary"
            mv "$temporary" "$bin_dir/amp"
          fi
        ) 9>"$AMP_HOME/.bootstrap.lock"

        export PATH="$bin_dir:$PATH"
        exec "$bin_dir/amp" "$@"
      '';
    };

    boatCliBinary = pkgs.fetchurl {
      url = "https://github.com/ariana-dot-dev/agent-server/releases/download/boat-cli-v1.0.36/boat-linux-x64";
      hash = "sha256-R8sr5CRCuiXVwc9YbZfcMppHe3lXSnEn8ta00inwgLw=";
    };

    boatCli = pkgs.writeShellApplication {
      name = "boat";
      runtimeInputs = [pkgs.coreutils pkgs.util-linux];
      text = ''
        bin_dir="$HOME/.ascii/bin"
        mkdir -p "$bin_dir"

        (
          flock 9
          if [[ ! -e "$bin_dir/boat" ]]; then
            temporary=$(mktemp "$bin_dir/.boat-bootstrap.XXXXXX")
            trap 'rm -f "$temporary"' EXIT
            install -m 0755 ${boatCliBinary} "$temporary"
            mv "$temporary" "$bin_dir/boat"
          fi
        ) 9>"$HOME/.ascii/.boat-bootstrap.lock"

        export PATH="$bin_dir:$PATH"
        exec "$bin_dir/boat" "$@"
      '';
    };
  in {
    packages =
      {
        check-branch-name = branchNameCheck;
        inherit commitizen;
        inherit (pkgs) nvfetcher;
        proton-ge = pkgs.callPackage ../../packages/proton-ge.nix {};
        orb-tools = pkgs.buildEnv {
          name = "nixconf-orb-tools";
          paths = [
            pkgs.direnv
            pkgs.nix-direnv
          ];
        };
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        amp-cli = ampCli;
        boat-cli = boatCli;
      };

    apps = {
      check-branch-name = {
        program = lib.getExe branchNameCheck;
        meta.description = "Validate a Git branch name";
      };
      commitizen = {
        program = lib.getExe commitizen;
        meta.description = "Validate Conventional Commits";
      };
      gitleaks = {
        program = lib.getExe pkgs.gitleaks;
        meta.description = "Scan Git history for leaked secrets";
      };
    };

    checks.proton-ge-aarch64 = pkgs.callPackage ../../packages/proton-ge.nix {arch = "aarch64";};
  };
}
