{username, ...}: {
  users.users.${username}.extraGroups = ["networkmanager" "video" "input" "audio" "docker" "cdrom" "dialout"];
}
