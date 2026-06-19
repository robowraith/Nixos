{
  programs.fish.functions = {
    # Unlock Bitwarden and export the session key into the current shell.
    bwu = ''
      set -gx BW_SESSION (bw unlock --raw)
      and echo "Bitwarden unlocked."
    '';
  };
}
