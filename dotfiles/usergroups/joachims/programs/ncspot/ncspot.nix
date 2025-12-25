{lib, ...}:{
  programs.ncspot.enable = true;

  xdg.configFile = {
    "ncspot/config.toml".source = lib.mkForce ./config.toml;
  };
}
