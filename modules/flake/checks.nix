{
  inputs,
  lib,
  ...
}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: let
    branchNameCheck = config.packages.check-branch-name;
    commitizen = config.packages.commitizen;
    workflowPolicy = config.packages.workflow-policy;

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

    notionCalendarCheck = let
      home = inputs.self.nixosConfigurations.t1.config.home-manager.users.mvs;
      mimeDefaults = home.xdg.mimeApps.defaultApplications;
      notionCalendar = inputs.monorepo.packages.x86_64-linux.notion-calendar;
      notionCalendarWaybar = home.programs.waybar.settings.mainBar."custom/notion-calendar";
    in
      assert lib.assertMsg (builtins.elem notionCalendar home.home.packages) "Notion Calendar is not installed";
      assert lib.assertMsg (builtins.any (package: lib.getName package == "todoist-electron") home.home.packages) "Todoist is not installed";
      assert lib.assertMsg (mimeDefaults."text/calendar" == ["com.cron.electron.desktop"]) "Notion Calendar is not the calendar default";
      assert lib.assertMsg (mimeDefaults."x-scheme-handler/cron" == ["com.cron.electron.desktop"]) "Notion Calendar is not the cron handler";
      assert lib.assertMsg (notionCalendarWaybar
        == {
          exec = "${notionCalendar}/bin/notion-calendar-waybar --follow";
          return-type = "json";
          escape = true;
          on-click = "${notionCalendar}/bin/notion-calendar-waybar --open";
          on-click-right = "${notionCalendar}/bin/notion-calendar-waybar --menu";
          tooltip = true;
        }) "Notion Calendar's Waybar module is misconfigured";
      assert lib.assertMsg (builtins.elem "custom/notion-calendar" home.programs.waybar.settings.mainBar.modules-right) "Notion Calendar is not visible in Waybar";
      assert lib.assertMsg (lib.hasInfix "#custom-notion-calendar.active { color: @accent; }" home.programs.waybar.style) "Notion Calendar's active Waybar style is missing";
      assert lib.assertMsg (builtins.elem "tray" home.programs.waybar.settings.mainBar."group/tray-expander".modules) "Waybar's StatusNotifierItem tray is missing";
        pkgs.runCommand "nixconf-notion-calendar" {} ''
          test -x ${notionCalendar}/bin/notion-calendar-waybar
          test -r ${notionCalendar}/share/applications/com.cron.electron.desktop
          touch "$out"
        '';
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
      settings.formatter.shfmt.excludes = ["scripts/amp-login-wizard.sh"];
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

    checks =
      {
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
      }
      // lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
        notion-calendar = notionCalendarCheck;
      };
  };
}
