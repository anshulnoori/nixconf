_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    home = {
      packages = [pkgs.lazydocker];
      sessionVariables.DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
    };
    programs.zsh.shellAliases.ld = "lazydocker";
  };
}
