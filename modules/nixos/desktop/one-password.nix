_: {
  flake.modules.nixos.desktop.programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = ["mvs"];
    };
  };

  flake.modules.homeManager.desktop = {
    lib,
    osConfig,
    ...
  }: {
    # Keep separate from the startup file managed by the app itself.
    xdg.configFile."autostart/nix-1password.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=1Password
      Exec=${lib.getExe osConfig.programs._1password-gui.package} --silent
      Terminal=false
    '';
  };
}
