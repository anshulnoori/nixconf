{
  lib,
  stdenv,
  fetchurl,
}: let
  releases = {
    x86_64-linux = {
      arch = "amd64";
      sha256 = "34aece7fb5931c637342431c53279907a65b97771f698e12ffdd7425d345d965";
    };
    aarch64-linux = {
      arch = "arm64";
      sha256 = "204be4cecc47b0774f068d9fd95e759bf4982f89ebde0cb88c6b0ceb19f4b506";
    };
  };
  release = releases.${stdenv.hostPlatform.system};
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "namespace-devbox";
    version = "0.0.184";

    src = fetchurl {
      url = "https://get.namespace.so/packages/devbox/v${finalAttrs.version}/devbox_${finalAttrs.version}_linux_${release.arch}.tar.gz";
      inherit (release) sha256;
    };

    sourceRoot = ".";
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 devbox "$out/bin/devbox"
      runHook postInstall
    '';

    doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
    installCheckPhase = ''
      runHook preInstallCheck
      HOME="$TMPDIR" "$out/bin/devbox" --help > /dev/null
      runHook postInstallCheck
    '';

    meta = {
      description = "Namespace Devbox CLI";
      homepage = "https://namespace.so/docs/reference/devbox-cli/installation";
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      license = lib.licenses.unfree;
      platforms = builtins.attrNames releases;
      mainProgram = "devbox";
    };
  })
