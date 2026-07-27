{pkgs, ...}: {
  # home-manager 26.05 renamed `programs.gemini-cli` to `programs.antigravity-cli`,
  # whose default package (`pkgs.antigravity-cli`) does not exist in nixpkgs 26.05.
  # Pin gemini-cli explicitly; this also trips the module's `useLegacyGeminiConfig`
  # auto-detection, keeping the existing ~/.gemini layout instead of Antigravity's.
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.gemini-cli;
  };
}
