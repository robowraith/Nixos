{pkgs, ...}: {
  ####################################
  # Configuration for the user jhoss #
  ####################################
  imports = [
    # Configuration shared by all users
    ../../shared
    # Configuration for usergroups this user belongs to
    ../../usergroups/joachims
    # Configuration specific for this user
    ./modules
    ./programs
  ];

  # User specific packages
  home.packages = with pkgs; [
  ];
}
