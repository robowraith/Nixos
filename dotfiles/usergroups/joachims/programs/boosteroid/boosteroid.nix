{
  pkgs,
  lib,
  ...
}: let
  boosteroid = pkgs.stdenv.mkDerivation rec {
    pname = "boosteroid";
    version = "2025-11-06";

    src = ./boosteroid-install-x64.deb;

    nativeBuildInputs = [
      pkgs.dpkg
      pkgs.autoPatchelfHook
      pkgs.makeWrapper
    ];

    buildInputs = with pkgs; [
      alsa-lib
      pulseaudio
      libva
      libvdpau
      numactl
      libglvnd
      libx11
      libxfixes
      libxi
      libxcb
      libxrandr
      libxrender
      libxext
      libxcursor
      libxinerama
      libxdamage
      libxcomposite
      libxkbfile
      libxau
      libxdmcp
      libxxf86vm
      libxscrnsaver
      libxtst
      libxcb-util
      libxcb-image
      libxcb-keysyms
      libxcb-render-util
      libxcb-wm
      xcbutilxrm
      libxkbcommon
      wayland
      dbus
      fontconfig
      freetype
      pcre2
      zlib
      xz
      libdrm
      udev
    ];

    unpackPhase = "dpkg-deb -x $src $out";

    installPhase = ''
      runHook preInstall

      substituteInPlace $out/usr/share/applications/Boosteroid.desktop \
        --replace "/opt/BoosteroidGamesS.R.L./bin/Boosteroid" "boosteroid" \
        --replace "/usr/share/icons/Boosteroid/icon.svg" "$out/usr/share/icons/Boosteroid/icon.svg"

      mkdir -p $out/bin
      ln -s $out/opt/BoosteroidGamesS.R.L./bin/Boosteroid $out/bin/boosteroid

      runHook postInstall
    '';

    meta = with lib; {
      description = "Boosteroid cloud gaming client";
      homepage = "https://boosteroid.com/";
      platforms = ["x86_64-linux"];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      license = licenses.unfreeRedistributable;
    };
  };
in {
  home.packages = [boosteroid];
}
