{
  inputs,
  pkgs,
  ...
}: {
  users.users.mvs = {
    isNormalUser = true;
    description = "Mervs";
    extraGroups = ["wheel"];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  home-manager.users.mvs = {
    imports = [inputs.self.modules.homeManager.base];
    home = {
      username = "mvs";
      homeDirectory = "/home/mvs";
      stateVersion = "26.05";
    };
  };
}
