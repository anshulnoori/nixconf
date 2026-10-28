{
  lib,
  stdenv,
  requireFile,
  dpkg,
  wrapGAppsHook3,
  webkitgtk_4_1,
  gst_all_1,
}:
stdenv.mkDerivation {
  pname = "synergy-dragon";
  version = "0.7.0";

  src = requireFile {
    name = "synergy-dragon-0.4.0-linux-trixie-x86_64.deb";
    hash = "sha256-rJd+7z62OK1M5a9mfavkR62PO4UziqxhjXfInAAMO0k=";
    url = "https://symless.com/synergy/download/synergy-dragon-alpha/v0.4.0";
  };

  updateBundle = requireFile {
    name = "synergy-dragon-0.7.0-linux-amd64.tar.gz";
    hash = "sha256-FhbaBBv3XJRiTPkSR4YzcBWRMWe/EQyOdGkjNjb9s/A=";
    url = "https://symless.com/synergy/api/update/synergy-dragon-alpha";
  };

  nativeBuildInputs = [dpkg wrapGAppsHook3];
  buildInputs = [
    webkitgtk_4_1
    gst_all_1.gst-plugins-base
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    tar -xzf "$updateBundle" -C usr/lib/synergy-dragon
    runHook postUnpack
  '';
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;
  dontWrapGApps = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/lib"
    cp -r usr/lib/synergy-dragon "$out/lib/"
    cp -r usr/share "$out/"
    ln -s "$out/lib/synergy-dragon/synergy-dragon-gui" "$out/bin/synergy-dragon-gui"
    runHook postInstall
  '';
  preFixup = ''
    wrapGApp "$out/bin/synergy-dragon-gui"
  '';

  meta = {
    description = "Synergy Dragon Alpha keyboard and mouse sharing";
    homepage = "https://symless.com/synergy";
    license = lib.licenses.unfree;
    platforms = ["x86_64-linux"];
    mainProgram = "synergy-dragon-gui";
  };
}
