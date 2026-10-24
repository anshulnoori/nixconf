_: {
  flake.modules.nixos.base = {
    lib,
    pkgs,
    ...
  }: let
    brotli = packages:
      packages.brotli.overrideAttrs {
        version = "1.2.1";
        src = packages.fetchFromGitHub {
          owner = "google";
          repo = "brotli";
          tag = "v1.2.1";
          hash = "sha256-llY72cYffDv0ugsH0p89xIPEbElV4L8u7U/Fe8hT3gI=";
        };
      };
    nodejs-slim =
      (pkgs.nodejs-slim_24.override {
        callPackage = path: args: pkgs.callPackage path (args // {brotli = brotli pkgs;});
      }).overrideAttrs {
        version = "24.22.1";
        src = pkgs.fetchurl {
          url = "https://nodejs.org/dist/v24.22.1/node-v24.22.1.tar.xz";
          hash = "sha256-T1N5eWKAza6wwvNY/QS2oWzE+336g7WoyRqdljtDUjE=";
        };
      };
    brotliFix = pkgs.fetchurl {
      url = "https://github.com/google/brotli/commit/0ed4268a4401abcb4472096340477cf4af7d1a2b.patch?full_index=1";
      hash = "sha256-1vliUJAAIj3vcGKVgim9CEV+XgMuftDR2U+3kLBUsfw=";
    };
    curl-impersonate = pkgs.curl-impersonate.overrideAttrs (old: {
      postPatch =
        old.postPatch
        + ''
          cat ${brotliFix} >> patches/brotli.patch
        '';
    });
    p7zip = pkgs.p7zip.overrideAttrs (old: {
      prePatch =
        (old.prePatch or "")
        + ''
          sed -i 's/\r$//' C/brotli/br_decode.c C/brotli/decode.h C/brotli/common/version.h
        '';
      patches = (old.patches or []) ++ [./p7zip-brotli-1.0.10.patch];
    });
    replace = old: new:
      map (output: {
        oldDependency = old.${output};
        newDependency = new.${output};
      })
      old.outputs;
  in {
    nixpkgs.overlays = [
      (_: prev: {
        replaceDirectDependencies = lib.makeOverridable (overrides: args: let
          result = prev.replaceDirectDependencies.override overrides args;
        in
          if args.replacements or [] != []
          then
            result.overrideAttrs (old: {
              buildCommand =
                builtins.replaceStrings
                [''echo "s|$oldBasename|$newBasename|g"'']
                [''echo "s|$oldBasename|$newBasename|g;s|''${oldBasename:0:32}|''${newBasename:0:32}|g"'']
                old.buildCommand;
            })
          else result) {};
      })
    ];

    system.replaceDependencies.replacements =
      lib.concatMap (packages: replace packages.brotli (brotli packages)) [
        pkgs
        pkgs.pkgsi686Linux
      ]
      ++ replace pkgs.nodejs-slim_24 nodejs-slim
      ++ replace pkgs.nodejs_24 (pkgs.nodejs_24.override {inherit nodejs-slim;})
      ++ replace pkgs.curl-impersonate curl-impersonate
      ++ replace pkgs.p7zip p7zip;
  };
}
