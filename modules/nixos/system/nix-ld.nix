_: {
  flake.modules.nixos.base.programs.nix-ld.enable = true;

  flake.modules.nixos.desktop = {pkgs, ...}: {
    programs.nix-ld.libraries = [
      pkgs.wayland
      pkgs.libxkbcommon
    ];
  };
}
