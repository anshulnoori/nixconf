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
          "amp-cli"
          "todoist-electron"
        ];
    };
  };
}
