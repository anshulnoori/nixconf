{inputs, ...}: {
  flake.modules.nixos.base = {lib, ...}: {
    imports = [inputs.lix-module.nixosModules.default];

    nix.settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      extra-substituters = [
        "https://anshulnoori.cachix.org"
        "https://attic.xuyh0120.win/lantian"
        "https://afnix-hydra.s3-bulk-web.afnix.fr/"
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "anshulnoori.cachix.org-1:jzLsepTKLr8/jDh8WdI4uhyimUTDSmxN5ispn1uN/Q0="
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
        "afnix:oqt801y+IwJ09XRtNDQYCKb7zuCw9DQXQk8fDWPkwxM="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    nixpkgs.config.allowUnfreePredicate = package:
      builtins.elem (lib.getName package) [
        "1password"
        "1password-cli"
        "amp-cli"
        "cuda_nvml_dev"
        "davinci-resolve"
        "discord-canary"
        "discord-canary-unwrapped"
        "objectbox-linux"
        "notion-calendar"
        "obsidian"
        "spotify"
        "steam"
        "steam-unwrapped"
        "todoist-electron"
      ];
  };
}
