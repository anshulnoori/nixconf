_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    programs.yazi = {
      enable = true;
      extraPackages = with pkgs; [
        fd
        ffmpegthumbnailer
        fzf
        imagemagick
        jq
        poppler-utils
        ripgrep
        zoxide
      ];
    };
  };

  flake.modules.homeManager.desktop.stylix.targets.yazi.enable = true;
}
