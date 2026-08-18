{username, ...}: {
  # Runs ResMon Plus (Contec RS10 sleep-apnea software) in a Windows VM —
  # the app doesn't work under Wine, but runs fine on stock Windows 11.
  #
  # onBoot = "ignore" keeps the daemon idle until a VM is started by hand.
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    # Windows 11 setup requires an emulated TPM 2.0 + secure-boot-capable
    # UEFI firmware; without it setup's hardware check blocks the install.
    qemu.swtpm.enable = true;
  };
  programs.virt-manager.enable = true;

  users.users.${username}.extraGroups = ["libvirtd"];
}
