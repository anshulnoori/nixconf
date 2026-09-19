_: {
  flake.modules.homeManager.base = {
    lib,
    pkgs,
    ...
  }: {
    xdg.configFile."git/allowed_signers".text = ''
      anshulnoori@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINjLNqd9uRYC2EpxIj6CoSSwe0KOZ3q0mJeMEiMH+ATE
      anshulnoori+github@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFzVmQzhajkwYF/s1jWyLwAAjGnmAhBqB3VEKP2S/Xwf
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
          user = {
            name = "Anshul Noori";
            email = "anshulnoori@gmail.com";
            signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINjLNqd9uRYC2EpxIj6CoSSwe0KOZ3q0mJeMEiMH+ATE";
            useConfigOnly = true;
          };
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
