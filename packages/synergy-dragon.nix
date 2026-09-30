{
  lib,
  stdenv,
  requireFile,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  qt6,
  webkitgtk_4_1,
  gst_all_1,
  openssl,
  libei,
  libportal,
  libx11,
  libxkbfile,
  libxtst,
  libxext,
  libxinerama,
  libxrandr,
  libxi,
  libxkbcommon,
}:
stdenv.mkDerivation {
  pname = "synergy-dragon";
  version = "0.5.0";

  # Keep the installer desktop entry and icons; replace its binaries below.
  src = requireFile {
    name = "synergy-dragon-0.4.0-linux-trixie-x86_64.deb";
    hash = "sha256-rJd+7z62OK1M5a9mfavkR62PO4UziqxhjXfInAAMO0k=";
    url = "https://symless.com/synergy/download/synergy-dragon-alpha/v0.4.0";
  };

  updateBundle = requireFile {
    name = "synergy-dragon-0.5.0-linux-amd64.tar.gz";
    hash = "sha256-yNSByniRXkB2WZjBXNRaqwjc39YXQVygQOdWBmuqiVY=";
    url = "https://symless.com/synergy/api/update/synergy-dragon-alpha";
  };

  nativeBuildInputs = [dpkg autoPatchelfHook wrapGAppsHook3 qt6.wrapQtAppsHook];
  buildInputs = [
    webkitgtk_4_1
    gst_all_1.gst-plugins-base
    qt6.qtbase
    qt6.qtwayland
    openssl
    libei
    libportal
    libx11
    libxkbfile
    libxtst
    libxext
    libxinerama
    libxrandr
    libxi
    libxkbcommon
    stdenv.cc.cc.lib
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    rm usr/lib/synergy-dragon/synergy-dragon-launcher
    tar -xzf "$updateBundle" -C usr/lib/synergy-dragon
    runHook postUnpack
  '';
  dontBuild = true;
  dontWrapGApps = true;
  dontWrapQtApps = true;
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
    wrapQtApp "$out/lib/synergy-dragon/synergy-core"
  '';

  meta = {
    description = "Synergy Dragon Alpha keyboard and mouse sharing";
    homepage = "https://symless.com/synergy";
    license = lib.licenses.unfree;
    platforms = ["x86_64-linux"];
    mainProgram = "synergy-dragon-gui";
  };
}
