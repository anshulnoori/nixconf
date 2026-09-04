_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    home.packages = [pkgs.lazyjournal];
    programs.zsh.shellAliases.lj = "lazyjournal";
  };
}
