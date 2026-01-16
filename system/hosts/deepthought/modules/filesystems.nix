{username, ...}: {
  home.cifs.mountPoints = map (name: "/home/${username}/Privat/${name}") [
    "Backup"
    "Bilder"
    "Dokumente"
    "Install"
    "Musik"
    "Videos"
  ];
}
