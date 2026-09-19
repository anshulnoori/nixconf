{
  lib,
  stdenvNoCC,
  fetchurl,
  _7zz,
  libarchive,
}:
stdenvNoCC.mkDerivation {
  pname = "sf-pro";
  version = "27.0.1789118100";
  src = fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
    hash = "sha256-loqzuLH5LC2K9h6waA9cIiTE541ZuYa/AEUCp/wBKRg=";
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
