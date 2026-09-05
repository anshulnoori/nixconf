_: {
  flake.modules.homeManager.base = {
    lib,
    pkgs,
    ...
  }: let
    realGit = lib.getExe pkgs.git;
    remoteAwareGit = pkgs.writeShellApplication {
      name = "git";
      text = ''
        context=()
        arguments=("$@")
        index=0

        while (( index < ''${#arguments[@]} )); do
          argument="''${arguments[$index]}"
          case "$argument" in
            -C|-c|--config-env|--git-dir|--namespace|--work-tree)
              next=$((index + 1))
              if (( next >= ''${#arguments[@]} )); then
                break
              fi
              context+=("$argument" "''${arguments[$next]}")
              index=$next
              ;;
            --config-env=*|--git-dir=*|--namespace=*|--work-tree=*|--bare)
              context+=("$argument")
              ;;
            --no-pager|--paginate)
              ;;
            --)
              break
              ;;
            -*)
              ;;
            *)
              break
              ;;
          esac
          index=$((index + 1))
        done

        origin="$(${realGit} "''${context[@]}" config --local --get remote.origin.url 2>/dev/null || true)"
        case "$origin" in
          ""|https://github.com/anshulnoori/*|ssh://git@github.com/anshulnoori/*|git@github.com:anshulnoori/*)
            exec ${realGit} \
              -c user.name="Anshul Noori" \
              -c user.email="anshulnoori+github@gmail.com" \
              -c user.signingKey="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINjLNqd9uRYC2EpxIj6CoSSwe0KOZ3q0mJeMEiMH+ATE" \
              "$@"
            ;;
          https://github.com/maroonverticalshape/*|ssh://git@github.com/maroonverticalshape/*|git@github.com:maroonverticalshape/*)
            exec ${realGit} \
              -c user.name="Mervs" \
              -c user.email="246713988+maroonverticalshape@users.noreply.github.com" \
              -c user.signingKey="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9q+hfnkUS3lNwGHuRprxjm6bd2Logahr2jHmLT+jC3" \
              "$@"
            ;;
          *)
            exec ${realGit} "$@"
            ;;
        esac
      '';
    };
  in {
    home.packages = [
      (lib.hiPrio remoteAwareGit)
    ];

    xdg.configFile."git/allowed_signers".text = ''
      anshulnoori+github@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINjLNqd9uRYC2EpxIj6CoSSwe0KOZ3q0mJeMEiMH+ATE
      246713988+maroonverticalshape@users.noreply.github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9q+hfnkUS3lNwGHuRprxjm6bd2Logahr2jHmLT+jC3
    '';

    programs = {
      git = {
        enable = true;
        settings = {
          alias = {
            br = "branch";
            ci = "commit";
            co = "checkout";
            st = "status";
          };
          commit.gpgSign = true;
          core.editor = "nvim";
          diff = {
            algorithm = "histogram";
            colorMoved = "zebra";
          };
          gpg = {
            format = "ssh";
            ssh = {
              allowedSignersFile = "~/.config/git/allowed_signers";
              program = lib.getExe' pkgs._1password-gui "op-ssh-sign";
            };
          };
          init.defaultBranch = "main";
          merge.conflictStyle = "zdiff3";
          pull.rebase = true;
          push.autoSetupRemote = true;
          rerere = {
            enabled = true;
            autoUpdate = true;
          };
          tag.gpgSign = true;
          user.useConfigOnly = true;
        };
      };

      gh = {
        enable = true;
        settings.git_protocol = "ssh";
      };

      delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          line-numbers = true;
          navigate = true;
          side-by-side = true;
          syntax-theme = "base16-stylix";
        };
      };

      lazygit.enable = true;

      zsh.shellAliases = {
        lg = "lazygit";
        lines = "git ls-files -z | xargs -0 wc -l";
      };
    };
  };

  flake.modules.homeManager.desktop.stylix.targets.lazygit.enable = true;
}
