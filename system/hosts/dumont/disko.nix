_: {
  # ============================================================================
  # Disk layout: Dell Wyse 3040, 8 GB eMMC
  # ============================================================================
  # GPT with an EFI system partition and ext4 on the rest. No swap partition
  # (zram from hostgroups/server). Applied by nixos-anywhere at install time;
  # afterwards it only provides fileSystems.

  disko.devices.disk.main = {
    type = "disk";
    # TODO(verify on hardware): the 3040's eMMC is expected to be mmcblk0
    device = "/dev/mmcblk0";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = ["noatime"];
          };
        };
      };
    };
  };
}
