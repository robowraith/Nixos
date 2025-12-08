{ config, lib, hostname, username, ... }:

{
  programs.git = {
    settings = {
      user = {
        name = "Joachim Hoss";
        email = "robowraith@gmail.com";
      };
    };
  };
}
