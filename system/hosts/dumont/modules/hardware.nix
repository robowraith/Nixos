{pkgs, ...}: {
  # ============================================================================
  # Firmware
  # ============================================================================
  # The full linux-firmware package is ~800 MiB, too much for the small eMMC.
  # The Wyse 3040 only needs firmware for its Realtek NIC and Intel graphics.
  # Verified on the installer ISO (2026-10-19): only r8169 (RTL8168h) and
  # i915 (Cherryview) bind, no missing-firmware messages.

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
