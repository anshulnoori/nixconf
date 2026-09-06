{
  callPackage,
  proton-ge-bin,
  runCommand,
  gnutar,
  gzip,
  stdenvNoCC,
  arch ? stdenvNoCC.hostPlatform.parsed.cpu.name,
}: let
  sources = callPackage ../_sources/generated.nix {};
  release = sources."proton-ge-${arch}";
in
  assert sources.proton-ge-x86_64.version == sources.proton-ge-aarch64.version;
    proton-ge-bin.overrideAttrs {
      inherit (release) version;
      toolName = "${release.version}-${arch}";
      src =
        runCommand "${release.version}-${arch}-source" {
          nativeBuildInputs = [gnutar gzip];
        } ''
          mkdir -p "$out"
          tar -xzf ${release.src} --strip-components=1 -C "$out"
        '';
    }
