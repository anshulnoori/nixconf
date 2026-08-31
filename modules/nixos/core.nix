{inputs, ...}: {
  flake.nixosModules = {
    disko = inputs.disko.nixosModules.disko;

    home-manager = {
      imports = [inputs.home-manager.nixosModules.home-manager];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {inherit inputs;};
      };
    };

    lix = inputs.lix-module.nixosModules.default;
  };
}
