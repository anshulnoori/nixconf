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
        # The app's suggested save name, for the save-here key (see chooser-save).
        if [ "''${3:-0}" = 1 ]; then
          YAZI_SAVE_NAME=$(basename -- "$4")
          export YAZI_SAVE_NAME
        fi
        # Reuse present-terminal's floating rule, without its pause or detached launch.
        export TERMCMD='${pkgs.kitty}/bin/kitty --class TUI.float --title termfilechooser'
        exec ${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh "$@"
      '';
    };
  in {
    stylix.targets.yazi.enable = true;

    programs.yazi = {
      plugins.chooser-quit = pkgs.writeTextDir "main.lua" ''
        ---@sync entry
        return {
          entry = function()
            if rt.args.chooser_file then
              ya.emit("quit", { no_cwd_file = true })
            else
              ya.emit("quit", {})
            end
          end,
        }
      '';
      # In a save dialog, save into the current folder under a name you confirm.
      # Nothing is created until you confirm, so browsing or cancelling leaves no file.
      plugins.chooser-save = pkgs.writeTextDir "main.lua" ''
        local get_cwd = ya.sync(function() return cx.active.current.cwd end)

        return {
          entry = function()
            local name = os.getenv("YAZI_SAVE_NAME")
            if not rt.args.chooser_file or not name then
              return ya.notify { title = "Save", content = "Not in a save dialog", timeout = 3, level = "warn" }
            end

            local value, event = ya.input { title = "Save as:", value = name, pos = { "center", w = 60 } }
            if event ~= 1 or value == "" then
              return
            end

            local target = get_cwd():join(value)
            if fs.cha(target) then
              local ok = ya.confirm {
                pos = { "center", w = 60, h = 8 },
                title = "Overwrite?",
                body = value .. " already exists. Replace it?",
              }
              if not ok then
                return
              end
            else
              local ok, err = fs.write(target, "")
              if not ok then
                return ya.notify { title = "Save", content = tostring(err), timeout = 5, level = "error" }
              end
            end

            ya.emit("open", { target })
          end,
        }
      '';
      keymap.mgr.prepend_keymap = [
        {
          on = "q";
          run = "plugin chooser-quit";
          desc = "Cancel chooser, otherwise quit";
        }
        {
          on = "<C-s>";
          run = "plugin chooser-save";
          desc = "Save here (file chooser)";
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
