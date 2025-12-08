{pkgs, ...}: {
  imports = [
    ../../shared
  ];

  # User specific packages
  home.packages = with pkgs; [
  ];
}
