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

  # The v4l backend exposes the webcam as a "scanner". It sorts ahead of the
  # real device, so frontends started without an explicit device argument grab
  # the webcam and fail with SANE_STATUS_INVAL. Nothing here scans via v4l.
  hardware.sane.disabledDefaultBackends = ["v4l"];

  # Graphical scanning frontend.
  environment.systemPackages = [pkgs.xsane];

  users.users.${username}.extraGroups = ["scanner"];
}
