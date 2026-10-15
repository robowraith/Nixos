{pkgs, ...}: {
  # ============================================================================
  # Firmware
  # ============================================================================
  # The full linux-firmware package is ~800 MiB, a tenth of the 8 GB eMMC.
  # The Wyse 3040 only needs firmware for its Realtek NIC and Intel graphics.
  # TODO(verify on hardware): `dmesg | grep -i firmware` on the installer ISO
  # (which ships everything) lists what the box actually loads.

  hardware = {
    enableRedistributableFirmware = false;
    cpu.intel.updateMicrocode = true;
    firmware = [
      (pkgs.runCommand "wyse3040-firmware" {} ''
        mkdir -p $out/lib/firmware
        cp -rL ${pkgs.linux-firmware}/lib/firmware/{rtl_nic,i915} $out/lib/firmware/
      '')
    ];
  };
}
