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

  flake.modules.homeManager.desktop = {
    config,
    pkgs,
    ...
  }: let
    chooser = pkgs.writeShellApplication {
      name = "yazi-file-chooser";
      runtimeInputs = [config.programs.yazi.finalPackage pkgs.kitty pkgs.gnused pkgs.coreutils pkgs.bash];
      text = ''
        export TERMCMD='${pkgs.kitty}/bin/kitty --title termfilechooser'
        exec ${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh "$@"
      '';
    };
  in {
    stylix.targets.yazi.enable = true;

    programs.yazi = {
      plugins.chooser-escape = pkgs.writeTextDir "main.lua" ''
        ---@sync entry
        return {
          entry = function()
            if rt.args.chooser_file then
              ya.emit("quit", { no_cwd_file = true })
            else
              ya.emit("escape", {})
            end
          end,
        }
      '';
      keymap.mgr.prepend_keymap = [
        {
          on = "<Esc>";
          run = "plugin chooser-escape";
          desc = "Cancel chooser, otherwise escape";
        }
      ];
    };

    xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
      [filechooser]
      cmd=${chooser}/bin/yazi-file-chooser
      default_dir=$HOME
      create_help_file=0
      open_mode=suggested
      save_mode=suggested
    '';
  };
}
