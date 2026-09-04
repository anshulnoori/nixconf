_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    programs.nvf.settings.vim = {
      startPlugins = [pkgs.vimPlugins.nvim-nio];
      lazy.plugins = {
        "amp.nvim" = {
          package = pkgs.vimPlugins.amp-nvim;
          event = "DeferredUIEnter";
          setupModule = "amp";
          setupOpts = {
            auto_start = true;
            log_level = "info";
          };
        };

        gradle-nvim = {
          package = "gradle-nvim";
          cmd = [
            "Gradle"
            "GradleExec"
            "GradleFavorites"
            "GradleInit"
          ];
          setupModule = "gradle";
          setupOpts.gradle_executable = "gradle";
        };

        "uv.nvim" = {
          package = pkgs.vimPlugins.uv-nvim.overrideAttrs {
            runtimeDeps = [];
          };
          ft = "python";
          setupModule = "uv";
        };

        vimtex = {
          package = pkgs.vimPlugins.vimtex;
          ft = [
            "plaintex"
            "tex"
          ];
        };
      };
    };
  };
}
