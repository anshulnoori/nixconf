{
  lib,
  stdenvNoCC,
  fetchurl,
  _7zz,
  libarchive,
}: let
  source = builtins.fromJSON (builtins.readFile ./sf-pro-source.json);
in
  stdenvNoCC.mkDerivation {
    pname = "sf-pro";
    inherit (source) version;
    src = fetchurl {
      inherit (source) url hash;
    };
    # Current Apple DMGs use APFS, which the older p7zip cannot unpack.
    nativeBuildInputs = [_7zz libarchive];
    unpackPhase = ''
      runHook preUnpack
      7zz e "$src" SFProFonts.pkg
      bsdtar -xOf SFProFonts.pkg SFProFontsPackage.pkg/Payload | bsdtar -xf -
      runHook postUnpack
    '';
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      install -Dm644 Library/Fonts/*.otf -t "$out/share/fonts/opentype"
      install -Dm644 Library/Fonts/*.ttf -t "$out/share/fonts/truetype"
      runHook postInstall
    '';
    meta.license = lib.licenses.unfree;
  }
