_: {
  perSystem = {config, ...}: {
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

    checks.treefmt = (config.treefmt.build.check config.treefmt.projectRoot).overrideAttrs {
      GIT_CONFIG_NOSYSTEM = "1";
      GIT_CONFIG_COUNT = "1";
      GIT_CONFIG_KEY_0 = "core.hooksPath";
      GIT_CONFIG_VALUE_0 = "/dev/null";
      PRE_COMMIT_ALLOW_NO_CONFIG = "1";
    };
  };
}
