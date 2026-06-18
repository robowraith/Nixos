{pkgs, ...}: {
  # gh is installed as a plain package (not programs.gh) so per-project
  # GH_CONFIG_DIR overrides (set via direnv) fully control account/config.
  home.packages = [pkgs.gh];
}
