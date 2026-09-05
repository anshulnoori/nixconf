_: {
  flake.modules.nixos.base = {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };
  };
}
