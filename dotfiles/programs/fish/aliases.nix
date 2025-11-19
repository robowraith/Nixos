{
  programs.fish.shellAliases = {
   cat = "bat";
   ccat = "bat --decorations never";
   cd = "__zoxide_z";
   cdi = "__zoxide_zi";
   grep = "rg -S";
   ll = "eza -aghl --group-directories-first --icons";
  };
}
