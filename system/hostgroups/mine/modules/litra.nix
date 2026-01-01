{ pkgs, ... }:
let
  litra-rs = pkgs.rustPlatform.buildRustPackage rec {
    pname = "litra-rs";
    version = "2.5.1";

    src = pkgs.fetchFromGitHub {
      owner = "timrogers";
      repo = "litra-rs";
      rev = "a7bdc49265cab3ed7f48f1a71ffd2e6996e0bd94"; # v2.5.1
      sha256 = "sha256-lUybdnaVfXUjbIMEBw4Ai5m0OMZ9XNEK5gGHty/yK0M=";
    };

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.libusb1 ];

    # Set to a fake hash initially. The build will fail and provide the correct hash.
    cargoHash = "sha256-j8T15LzA8ZjzNdI+UuHDhMIpYCdWdXR+cU7BgYt5Rno=";

    meta = with pkgs.lib; {
      description = "Control your Logitech Litra light from the command line";
      homepage = "https://github.com/timrogers/litra-rs";
      license = licenses.mit;
      maintainers = [];
      mainProgram = "litra";
    };
  };
in
{
  environment.systemPackages = [ litra-rs ];

  services.udev.extraRules = ''
    # Logitech Litra Glow
    SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c900", MODE="0666", GROUP="video", TAG+="uaccess"
    KERNEL=="hidraw*", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c900", MODE="0666", GROUP="video", TAG+="uaccess"

    # Logitech Litra Beam
    SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c901", MODE="0666", GROUP="video", TAG+="uaccess"
    KERNEL=="hidraw*", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c901", MODE="0666", GROUP="video", TAG+="uaccess"

    # Logitech Litra Beam LX
    SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c903", MODE="0666", GROUP="video", TAG+="uaccess"
    KERNEL=="hidraw*", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c903", MODE="0666", GROUP="video", TAG+="uaccess"
  '';
}
