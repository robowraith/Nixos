{
  config,
  pkgs,
  username,
  ...
}: {
  # ============================================================================
  # SOPS integration for user password
  # ============================================================================
  # This tells sops-nix to manage the secret with the corresponding key
  # from your secrets.yml file. We use the `username` variable to keep
  # this module generic. Make sure your secret is named e.g. "joachim_password_hash".
  sops.secrets."users_${username}_password_hash" = {
    # No extra options needed for this, sops-nix just extracts the value.
  };

  # ============================================================================
  # Users
  # ============================================================================

  users.groups.${username} = {
    gid = 1000;
  };

  users.users.${username} = {
    uid = 1000;
    group = username;
    isNormalUser = true;
    createHome = true;
    extraGroups = ["networkmanager" "wheel" "video" "input" "audio" "docker" "cdrom"];
    shell = pkgs.fish;
    # This points to the decrypted file containing the hashed password.
    # sops-nix provides this path.
    hashedPasswordFile = config.sops.secrets."users_${username}_password_hash".path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOvw24pG1yoIoRJOG9txTtN8YC5gVy5uURs59CwY1jIh jhoss"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC7xEgQh5j5zse3gFZmIUzfbtVIsYaZ4ksBT/Sx0dshm joachim"
    ];
  };
}
