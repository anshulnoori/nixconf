{inputs, ...}: {
  flake.nixosConfigurations.t1 = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {inherit inputs;};
    modules = [../../hosts/t1];
  };
}
