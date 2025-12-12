{pkgs, ...}: {
  imports = [
    # Configuration shared by all users
    ../../shared
    # Configuration for usergroups this user belongs to
    #../../usergroups
    # Configuration specific for this user
    ./modules
    ./programs
  ];

  # User specific packages
  home.packages = with pkgs; [
  ];
}
