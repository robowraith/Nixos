{
  config,
  lib,
  hostname,
  ...
}: {
  options.fleet.sops.perHostKey = lib.mkEnableOption ''
    a per-host sops identity: decrypt secrets/<hostname>.yaml with the age key derived
    from the host's SSH host key instead of the shared age key, which never lands on the host
  '';

  config.sops =
    if config.fleet.sops.perHostKey
    then {
      defaultSopsFile = ../../../secrets/${hostname}.yaml;
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      # Don't fall back to the shared key file or GnuPG
      age.keyFile = null;
      gnupg.sshKeyPaths = [];
    }
    else {
      defaultSopsFile = ../../../secrets/shared.yaml;
      age.keyFile = "/var/lib/sops/age/keys.txt";
    };
}
