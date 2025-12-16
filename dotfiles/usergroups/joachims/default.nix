{pkgs, ...}: {
  imports = [
    # Configuration shared by all users
    ../../shared
    # Configuration specific for this usergroup
    ./modules
    ./programs
  ];

  # User specific packages
  home.packages = with pkgs; [
    lxqt.lxqt-policykit
  ];
}
