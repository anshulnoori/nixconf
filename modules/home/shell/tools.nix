_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    home.packages = with pkgs; [
      asciinema
      gron
      htmlq
      hyperfine
      jc
      miller
      ouch
      sd
      watchexec
      yq
      zmx
    ];

    programs = {
      jq.enable = true;
      tealdeer.enable = true;
      zsh.shellAliases.h = "hyperfine";
    };
  };
}
