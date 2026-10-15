_: {
  # Decrypt only secrets/dumont.yaml, with the age identity derived from the
  # SSH host key; the shared age key never lands on this host.
  fleet.sops.perHostKey = true;
}
