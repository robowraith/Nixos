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

  # Halt running Vagrant libvirt VMs on system shutdown so libvirt does not
  # flag them as inaccessible after reboot.
  systemd.services.vagrant-halt = {
    description = "Halt Vagrant libvirt VMs on system shutdown";
    requires = ["libvirtd.service"];
    after = ["libvirtd.service"];
    wantedBy = ["multi-user.target"];
    path = with pkgs; [vagrant libvirt];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = username;
      WorkingDirectory = "/home/${username}/code/ansible/vagrant";
      ExecStart = "${pkgs.coreutils}/bin/true";
      ExecStop = "${pkgs.vagrant}/bin/vagrant halt --force";
      TimeoutStopSec = 120;
    };
  };
}
