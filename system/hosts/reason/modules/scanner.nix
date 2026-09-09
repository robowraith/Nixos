{
  pkgs,
  username,
  ...
}: {
  # Canon CanoScan 9000F Mark II (USB 04a9:190d), driven by the SANE `pixma`
  # backend that ships with sane-backends.
  #
  # `hardware.sane.enable` installs sane-backends (scanimage), its udev/hwdb
  # rules and the ACL rule that grants the `scanner` group access to matched
  # devices, so no hand-written udev rule is needed for this scanner.
  hardware.sane.enable = true;

  # Graphical scanning frontend.
  environment.systemPackages = [pkgs.xsane];

  users.users.${username}.extraGroups = ["scanner"];
}
