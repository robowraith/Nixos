{pkgs, ...}: {
  # Enable Stylix system module with catppuccin-mocha theme
  services.stylix = {
    enable = true;
    theme = "catppuccin-mocha";
    packages = with pkgs; [stylix];
  };
}
