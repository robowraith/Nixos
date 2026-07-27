{pkgs, ...}: {
  # Single OpenSSH agent per login session as a systemd user service.
  # Binds to a fixed socket ($XDG_RUNTIME_DIR/ssh-agent); home-manager's
  # sshAuthSock module then exports SSH_AUTH_SOCK in every shell, so the
  # path never goes stale (unlike exporting it as a universal fish variable).
  services.ssh-agent.enable = true;

  # Backport of home-manager master commit f1d5aa6f ("sshAuthSock: set in
  # systemd"), which landed 2026-06-02 — just after release-26.05 was branched,
  # so it only ships in 26.11.
  #
  # The shell-level export above never reaches graphical apps started by
  # systemd/D-Bus. Without this, KeePassXC inherits whatever SSH_AUTH_SOCK the
  # session began with and adds unlocked keys to a stale socket, so git falls
  # back to prompting for the key passphrase.
  #
  # Drop this block when upgrading to 26.11 — upstream `sshAuthSock.enable`
  # replaces it.
  systemd.user.services.set-ssh-auth-sock = {
    Unit = {
      Description = "Publish SSH_AUTH_SOCK to systemd and the D-Bus daemon";
      # Ordered before the agent rather than after it: socket units are already
      # ordered before sockets.target, so requiring the agent first would close
      # a cycle through basic.target.
      Before = ["ssh-agent.service"];
    };
    Service = {
      Type = "oneshot";
      # %t expands to $XDG_RUNTIME_DIR for user units.
      ExecStart = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd SSH_AUTH_SOCK=%t/ssh-agent";
    };
    Install.WantedBy = ["default.target" "ssh-agent.service"];
  };
}
