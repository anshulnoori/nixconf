{
  inputs,
  pkgs,
  ...
}: {
  users.users.mvs = {
    isNormalUser = true;
    description = "Mervs";
    extraGroups = ["wheel" "librepods"];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  home-manager.users.mvs = {
    imports = [
      inputs.self.modules.homeManager.base
      inputs.self.modules.homeManager.desktop
      inputs.self.modules.homeManager.gaming
    ];
    home = {
      username = "mvs";
      homeDirectory = "/home/mvs";
      stateVersion = "26.05";
    };
    services.nixconf-update.enable = true;
  };
}
