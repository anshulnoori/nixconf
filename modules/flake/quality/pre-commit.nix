{lib, ...}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: let
    branchNameCheck = config.packages.check-branch-name;
    commitizen = config.packages.commitizen;
  in {
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

    checks.pre-commit = config.pre-commit.settings.run.overrideAttrs {
      GIT_CONFIG_NOSYSTEM = "1";
    };
  };
}
