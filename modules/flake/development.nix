{lib, ...}: {
  perSystem = {
    config,
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

    workflowPolicy = pkgs.writeShellApplication {
      name = "check-workflows";
      runtimeInputs = [
        pkgs.actionlint
        pkgs.ripgrep
        pkgs.shellcheck
      ];
      text = ''
        exec ${../../scripts/check-workflows.sh} ${../..}
      '';
    };

    gitConventionsCheck =
      pkgs.runCommand "nixconf-git-conventions" {
        nativeBuildInputs = [
          branchNameCheck
          commitizen
          pkgs.gitMinimal
        ];
      } ''
        for branch in \
          master \
          feat/add-desktop-host \
          flake/update-nixpkgs \
          host/add-t1 \
          module/add-audio \
          renovate/nix-flake-inputs; do
          check-branch-name "$branch"
        done

        for branch in \
          main \
          feature/add-host \
          feat/Add-host \
          feat/add_host \
          feat/add/host \
          feat/add--host \
          release/v1; do
          if check-branch-name "$branch" 2>/dev/null; then
            printf 'Expected invalid branch name to fail: %s\n' "$branch" >&2
            exit 1
          fi
        done

        cz check --allowed-prefixes --message 'feat(host): add fixture'
        cz check --allowed-prefixes --message $'feat(host): add fixture\n\nExplain the reason.\n\nRefs: #1'
        cz check --allowed-prefixes --message 'revert: restore previous kernel'
        for message in \
          'add host' \
          'Merge branch master' \
          'Revert "feat(host): add fixture"' \
          'fixup! feat(host): add fixture' \
          'squash! feat(host): add fixture'; do
          if cz check --allowed-prefixes --message "$message" >/dev/null 2>&1; then
            printf 'Expected invalid commit message to fail: %s\n' "$message" >&2
            exit 1
          fi
        done

        export GIT_AUTHOR_NAME='Git conventions test'
        export GIT_AUTHOR_EMAIL='git-conventions@example.invalid'
        export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
        export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
        git init --quiet repository
        cd repository
        git commit --quiet --allow-empty --message 'chore: initialize fixture'
        git commit --quiet --allow-empty --message 'feat(host): add fixture'
        git commit --quiet --allow-empty --message 'fix(module): update fixture'
        cz check --allowed-prefixes --rev-range HEAD~2..HEAD
        git commit --quiet --allow-empty --message 'temporary snapshot'
        if cz check --allowed-prefixes --rev-range HEAD~1..HEAD >/dev/null 2>&1; then
          printf 'Expected invalid commit range to fail\n' >&2
          exit 1
        fi

        touch "$out"
      '';

    workflowPolicyCheck =
      pkgs.runCommand "nixconf-workflow-policy" {
        nativeBuildInputs = [workflowPolicy];
      } ''
        check-workflows
        touch "$out"
      '';

    ampPluginCheck =
      pkgs.runCommand "nixconf-amp-plugin" {
        nativeBuildInputs = [pkgs.bun];
      } ''
        cp -R ${../../.amp/plugins/renovate-review} renovate-review
        chmod -R u+w renovate-review
        cd renovate-review
        bun test index.test.ts
        touch "$out"
      '';

    renovateConfigCheck =
      pkgs.runCommand "nixconf-renovate-config" {
        nativeBuildInputs = [pkgs.renovate];
      } ''
        renovate-config-validator --strict ${../../renovate.json}
        touch "$out"
      '';

    ampCliRelease = {
      version = "0.0.1788134497-gb6ce09";
      source = {
        platform = "linux-x64-baseline";
        hash = "sha256-ZwoZF9xl93hVEtC2fygcE9ccvJMPZJt0Ih+zmec9w7w=";
      };
    };

    ampCli = pkgs.amp-cli.overrideAttrs (_: {
      inherit (ampCliRelease) version;
      src = pkgs.fetchurl {
        url = "https://static.ampcode.com/cli/${ampCliRelease.version}/amp-${ampCliRelease.source.platform}.gz";
        inherit (ampCliRelease.source) hash;
      };
    });

    installerShell = pkgs.mkShellNoCC {
      packages = with pkgs; [
        ampCli
        bat
        curl
        dmidecode
        ethtool
        fwupd
        git
        gnugrep
        iproute2
        iputils
        jq
        kmod
        less
        lm_sensors
        nvme-cli
        openssh
        pciutils
        ripgrep
        rsync
        smartmontools
        tmux
        usbutils
        util-linux
      ];
    };
  in {
    treefmt = {
      flakeCheck = false;
      programs = {
        alejandra.enable = true;
        prettier = {
          enable = true;
          includes = [
            "*.json"
            "*.md"
            "*.yaml"
            "*.yml"
          ];
        };
        shfmt.enable = true;
      };
    };

    pre-commit.check.enable = false;
    pre-commit.settings.hooks = {
      commitizen = {
        enable = true;
        package = commitizen;
        entry = "${lib.getExe commitizen} check --allow-abort --allowed-prefixes --commit-msg-file";
        stages = ["commit-msg"];
      };
      branch-name = {
        enable = true;
        name = "branch name";
        entry = lib.getExe branchNameCheck;
        pass_filenames = false;
        always_run = true;
        stages = ["pre-push"];
      };
      treefmt = {
        enable = true;
        stages = ["pre-commit"];
      };
      statix = {
        enable = true;
        stages = ["pre-commit"];
      };
      deadnix = {
        enable = true;
        stages = ["pre-commit"];
      };
      actionlint = {
        enable = true;
        stages = ["pre-commit"];
      };
      workflow-policy = {
        enable = true;
        name = "GitHub workflow policy";
        package = workflowPolicy;
        entry = lib.getExe workflowPolicy;
        files = "^(\\.github/|scripts/check-workflows\\.sh$)";
        pass_filenames = false;
        stages = ["pre-commit"];
      };
      amp-plugins = {
        enable = true;
        name = "Amp Renovate review plugin";
        package = pkgs.bun;
        entry = "${lib.getExe pkgs.bun} test ./.amp/plugins/renovate-review/index.test.ts";
        files = "^\\.amp/plugins/renovate-review/";
        pass_filenames = false;
        stages = ["pre-commit"];
      };
      gitleaks = {
        enable = true;
        name = "Gitleaks";
        package = pkgs.gitleaks;
        entry = "${lib.getExe pkgs.gitleaks} git --staged --redact=100 --no-banner --no-color";
        pass_filenames = false;
        always_run = true;
        stages = ["pre-commit"];
      };
      renovate-config = {
        enable = true;
        name = "Renovate config";
        package = pkgs.renovate;
        entry = "${lib.getExe' pkgs.renovate "renovate-config-validator"} --strict";
        files = "^renovate\\.json$";
        stages = ["pre-commit"];
      };
      shellcheck = {
        enable = true;
        files = "^(\\.agents/(setup|resume)|scripts/.*\\.sh)$";
        stages = ["pre-commit"];
      };
      nix-flake-eval = {
        enable = true;
        name = "Nix flake evaluation";
        entry = "nix flake check --all-systems --no-build .";
        pass_filenames = false;
        always_run = true;
        stages = ["pre-push"];
      };
    };

    packages =
      {
        check-branch-name = branchNameCheck;
        orb-tools = pkgs.buildEnv {
          name = "nixconf-orb-tools";
          paths = [
            pkgs.cachix
            pkgs.direnv
            pkgs.nix-direnv
          ];
        };
        workflow-policy = workflowPolicy;
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        amp-cli = ampCli;
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
      workflow-policy = {
        program = lib.getExe workflowPolicy;
        meta.description = "Validate GitHub workflow policy";
      };
    };

    checks = {
      amp-plugin = ampPluginCheck;
      git-conventions = gitConventionsCheck;
      pre-commit = config.pre-commit.settings.run.overrideAttrs {
        GIT_CONFIG_NOSYSTEM = "1";
      };
      renovate-config = renovateConfigCheck;
      treefmt = (config.treefmt.build.check config.treefmt.projectRoot).overrideAttrs {
        GIT_CONFIG_NOSYSTEM = "1";
        GIT_CONFIG_COUNT = "1";
        GIT_CONFIG_KEY_0 = "core.hooksPath";
        GIT_CONFIG_VALUE_0 = "/dev/null";
        PRE_COMMIT_ALLOW_NO_CONFIG = "1";
      };
      workflow-policy = workflowPolicyCheck;
    };

    devShells =
      {
        default = pkgs.mkShellNoCC {
          packages =
            config.pre-commit.settings.enabledPackages
            ++ [
              pkgs.bun
              pkgs.cachix
              pkgs.git
              pkgs.jq
              pkgs.nil
              pkgs.pre-commit
              pkgs.renovate
            ];
          shellHook = config.pre-commit.installationScript;
        };
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        installer = installerShell;
      };
  };
}
