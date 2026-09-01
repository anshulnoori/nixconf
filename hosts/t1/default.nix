{inputs, ...}: {
  imports = [
    inputs.self.modules.nixos.base
    ./disko.nix
    ./hardware.nix
    ./networking.nix
    ../../users/mvs
  ];

  networking.hostName = "t1";
}
