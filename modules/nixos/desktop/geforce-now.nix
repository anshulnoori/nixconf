{inputs, ...}: {
  flake.modules.nixos.desktop = {lib, ...}: {
    imports = [inputs.nix-flatpak.nixosModules.nix-flatpak];

    services.flatpak = {
      enable = true;
      remotes = lib.mkOptionDefault [
        {
          name = "GeForceNOW";
          location = "https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo";
        }
      ];
      packages = [
        {
          appId = "com.nvidia.geforcenow";
          origin = "GeForceNOW";
        }
      ];
    };
  };
}
