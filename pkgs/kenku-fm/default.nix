{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libxcb,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
}:
stdenv.mkDerivation rec {
  pname = "kenku-fm";
  version = "1.5.4";

  src = fetchurl {
    url = "https://github.com/owlbear-rodeo/kenku-fm/releases/download/v${version}/kenku-fm_${version}_amd64.deb";
    hash = "sha256-iItWx+rv0jOTBcPaa3ieCf28OI/HvcnRjGqxEw0O0cU=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxcb
    libxkbcommon
    mesa
    nspr
    nss
    pango
    systemd
  ];

  unpackPhase = ''
    dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/bin $out/share

    cp -r usr/lib/kenku-fm $out/lib/kenku-fm
    cp -r usr/share/* $out/share/

    # Wrap the binary with required environment
    makeWrapper $out/lib/kenku-fm/kenku-fm $out/bin/kenku-fm \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"

    # Fix desktop file paths
    substituteInPlace $out/share/applications/kenku-fm.desktop \
      --replace-fail "Exec=kenku-fm" "Exec=$out/bin/kenku-fm"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Online tabletop audio sharing for Discord";
    homepage = "https://github.com/owlbear-rodeo/kenku-fm";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "kenku-fm";
  };
}
