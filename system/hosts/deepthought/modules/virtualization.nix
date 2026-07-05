{
  pkgs,
  username,
  ...
}: {
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
  };
  programs.virt-manager.enable = true;

  users.users.${username}.extraGroups = ["libvirtd"];

  environment.systemPackages = with pkgs; [
    vagrant
  ];
}
