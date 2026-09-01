{inputs, ...}: {
  imports = [
    inputs.self.modules.nixos.base
    inputs.self.modules.nixos.desktop
    ./disko.nix
    ./hardware.nix
    ./networking.nix
    ../../users/mvs
  ];

  networking.hostName = "t1";
}
