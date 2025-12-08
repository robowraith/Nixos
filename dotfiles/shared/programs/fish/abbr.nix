{
  programs.fish.shellAbbrs = {
    cl = "clear";
    d = "docker";
    dc = "docker compose";
    hc = "herbstclient";
    hms = "home-manager switch --flake ~/nixos#joachim@reason -b backup";
    k = "kubectl";
    kc = "kubectl";
    lg = "lazygit";
    nfu = "sudo nix flake update --flake ~/nixos";
    nrs = "sudo nixos-rebuild switch --flake ~/nixos#reason";
    zj = "zellij";
  };
}
