{
  programs.fish.shellAliases = {
    # cat = "bat";
    ccat = "bat --decorations never";
    cd = "__zoxide_z";
    cdi = "__zoxide_zi";
    grep = "rg -S";
    helix = "hx";
    ll = "eza -aghl --group-directories-first --icons";
    psg = "procs";
    sarpl = "serpl";
    # age key stays root-only, so sops runs as root
    sops = "sudo env SOPS_AGE_KEY_FILE=/var/lib/sops/age/keys.txt EDITOR=hx sops";
  };
}
