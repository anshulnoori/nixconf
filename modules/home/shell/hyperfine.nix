_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    home.packages = [pkgs.hyperfine];
    programs.zsh.shellAliases.h = "hyperfine";
  };
}
