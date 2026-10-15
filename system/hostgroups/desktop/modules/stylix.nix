{pkgs, ...}: {
  # Enable Stylix
  stylix = {
    enable = true;
    enableReleaseChecks = false;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    # The gtksourceview target overlays the package, changing the hash of
    # everything that depends on it (e.g. inkscape) and forcing source builds.
    targets.gtksourceview.enable = false;
  };
}
