{inputs, ...}: {
  systems = [
    "aarch64-linux"
    "x86_64-linux"
  ];

  imports = [
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = {system, ...}: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfreePredicate = package:
        inputs.nixpkgs.lib.getName package == "amp-cli";
    };
  };
}
