# PLACEHOLDER until the first install. nixos-anywhere regenerates this file
# from the real hardware (--generate-hardware-config nixos-generate-config,
# see docs/runbooks/dumont-install.md); after that, do not edit it by hand.
# fileSystems come from disko.nix, so they are not listed here.
{modulesPath, ...}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Typical for the Wyse 3040 (Atom x5-Z8350, eMMC, USB boot)
  boot = {
    initrd.availableKernelModules = ["xhci_pci" "usb_storage" "sd_mod" "sdhci_acpi" "mmc_block"];
    kernelModules = ["kvm-intel"];
  };
}
