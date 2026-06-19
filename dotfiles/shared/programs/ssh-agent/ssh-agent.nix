{
  # Single OpenSSH agent per login session as a systemd user service.
  # Binds to a fixed socket ($XDG_RUNTIME_DIR/ssh-agent) and sets
  # SSH_AUTH_SOCK for all shells, so the socket path never goes stale
  # (unlike manually exporting it as a universal fish variable).
  services.ssh-agent.enable = true;
}
