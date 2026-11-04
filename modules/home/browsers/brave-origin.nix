_: {
  flake.modules = {
    nixos.desktop = {
      programs.chromium = {
        enable = true;
        extensions = ["aeblfdkhhhdcdjpifhhbdiojplfjncoa"];
        extraOpts.PasswordManagerEnabled = false;
      };

      stylix.targets.chromium.enable = true;
    };

    homeManager.desktop = {pkgs, ...}: {
      home.packages = [pkgs.brave-origin];
      home.sessionVariables.BROWSER = "brave-origin";
    };
  };
}
