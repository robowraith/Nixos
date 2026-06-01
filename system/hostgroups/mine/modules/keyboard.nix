{
  pkgs,
  username,
  ...
}: {
  hardware.keyboard.qmk.enable = true;

  environment.systemPackages = [pkgs.vial];

  services.udev.packages = [pkgs.vial];

  users.users.${username}.extraGroups = ["plugdev"];
}
