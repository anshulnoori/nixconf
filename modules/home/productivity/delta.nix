{inputs, ...}: {
  flake.modules.homeManager.desktop = {
    lib,
    pkgs,
    ...
  }: {
    # Zed's Delta owns the `delta` command; git's pager calls git-delta by store path.
    home.packages = [
      (lib.hiPrio inputs.delta.packages.${pkgs.stdenv.hostPlatform.system}.delta)
    ];
  };
}
