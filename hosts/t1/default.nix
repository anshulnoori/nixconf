{inputs, ...}: {
  imports = [
    inputs.self.modules.nixos.base
    inputs.self.modules.nixos.desktop
    inputs.self.modules.nixos.gaming
    ./disko.nix
    ./hardware.nix
    ./networking.nix
    ../../users/mvs
  ];

  networking.hostName = "t1";
}
