_: {
  flake.modules.nixos.desktop.programs.chromium = {
    enable = true;
    extensions = ["aeblfdkhhhdcdjpifhhbdiojplfjncoa"];
    extraOpts.PasswordManagerEnabled = false;
  };

  flake.modules.nixos.desktop.stylix.targets.chromium.enable = true;
}
