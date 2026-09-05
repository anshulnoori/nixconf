{inputs, ...}: {
  systems = [
    "aarch64-linux"
    "x86_64-linux"
  ];

  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = {system, ...}: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfreePredicate = package:
        builtins.elem (inputs.nixpkgs.lib.getName package) [
          "1password"
          "1password-cli"
          "amp-cli"
          "cuda_nvml_dev"
          "davinci-resolve"
          "discord-canary"
          "discord-canary-unwrapped"
          "objectbox-linux"
          "obsidian"
          "sf-pro"
          "spotify"
          "steam"
          "steam-unwrapped"
          "todoist-electron"
        ];
    };
  };
}
