{
  pkgs,
  lib,
  ...
}: let
  # The .deb (1.10.4) provides libs, desktop entry and icons; the main binary
  # comes from the same unversioned tarball the in-app updater downloads,
  # which can't self-install into the read-only store. Bump hash to update.
  binTar = pkgs.fetchurl {
    url = "https://boosteroid.com/linux/installer/boosteroid.tar";
    hash = "sha256-n7mt7YrHgjWyVWqoL9njXTbyaTKVBZOSH7/IkPVJRxY=";
    # Cloudflare 403s the default curl User-Agent; pretend to be a browser.
    curlOptsList = [
      "-A"
      "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    ];
  };

  boosteroid = pkgs.stdenv.mkDerivation rec {
    pname = "boosteroid";
    version = "1.10.23";

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

      tar -xf ${binTar} -C $out/opt/BoosteroidGamesS.R.L./bin Boosteroid
      chmod +x $out/opt/BoosteroidGamesS.R.L./bin/Boosteroid

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
