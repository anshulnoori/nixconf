_: {
  flake.modules.nixos.desktop.programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = ["mvs"];
    };
  };
}
