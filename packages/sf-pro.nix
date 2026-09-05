{
  lib,
  stdenvNoCC,
  fetchurl,
  p7zip,
  libarchive,
}:
stdenvNoCC.mkDerivation {
  pname = "sf-pro";
  version = "2026-07-30";
  src = fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
    hash = "sha256-qQlPDem3idc1RO5Q/FKgiE1Kn3/PYt5Sl04yBPOnSmI=";
  };
  # Build-only tools: ouch does not support Apple's DMG installer.
  nativeBuildInputs = [p7zip libarchive];
  unpackPhase = ''
    runHook preUnpack
    7z e "$src" 'SFProFonts/SF Pro Fonts.pkg'
    bsdtar -xOf 'SF Pro Fonts.pkg' SFProFonts.pkg/Payload | bsdtar -xf -
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
