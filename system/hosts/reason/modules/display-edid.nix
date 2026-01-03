{ pkgs, ... }:

{
  # Supply the EDID firmware
  hardware.firmware = [
    (pkgs.runCommand "edid-firmware" { } ''
      mkdir -p $out/lib/firmware/edid
      cp ${../edid.bin} $out/lib/firmware/edid/edid.bin
    '')
  ];

  # Force the kernel to use it
  # We use the connector name found in /sys/class/drm (HDMI-A-1)
  boot.kernelParams = [ "drm.edid_firmware=HDMI-A-1:edid/edid.bin" ];
}
