{
  inputs,
  lib,
  ...
}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    commitizen = pkgs.commitizen.overridePythonAttrs (_: {doCheck = false;});

    branchNameCheck = pkgs.writeShellApplication {
      name = "check-branch-name";
      runtimeInputs = [pkgs.gitMinimal];
      text = builtins.readFile ../../scripts/check-branch-name.sh;
    };

    ampCliRelease = {
      version = "0.0.1788134497-gb6ce09";
      source = {
        platform = "linux-x64-baseline";
        hash = "sha256-ZwoZF9xl93hVEtC2fygcE9ccvJMPZJt0Ih+zmec9w7w=";
      };
    };

    ampCli = pkgs.amp-cli.overrideAttrs (_: {
      inherit (ampCliRelease) version;
      src = pkgs.fetchurl {
        url = "https://static.ampcode.com/cli/${ampCliRelease.version}/amp-${ampCliRelease.source.platform}.gz";
        inherit (ampCliRelease.source) hash;
      };
    });

    ampDesktopStack = pkgs.callPackage "${inputs.monorepo}/src/amp-desktop/nix/stack.nix" {};
  in {
    packages =
      {
        inherit (ampDesktopStack) amp-desktop amp-desktop-webkitgtk credentialsd xdg-desktop-portal-credential;
        check-branch-name = branchNameCheck;
        inherit commitizen;
        orb-tools = pkgs.buildEnv {
          name = "nixconf-orb-tools";
          paths = [
            pkgs.cachix
            pkgs.direnv
            pkgs.nix-direnv
          ];
        };
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        amp-cli = ampCli;
      };

    apps = {
      check-branch-name = {
        program = lib.getExe branchNameCheck;
        meta.description = "Validate a Git branch name";
      };
      commitizen = {
        program = lib.getExe commitizen;
        meta.description = "Validate Conventional Commits";
      };
      gitleaks = {
        program = lib.getExe pkgs.gitleaks;
        meta.description = "Scan Git history for leaked secrets";
      };
    };
  };
}
