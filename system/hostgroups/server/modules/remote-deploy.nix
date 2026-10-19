_: {
  # ============================================================================
  # Remote deploys
  # ============================================================================
  # Servers are built on a desktop and the closure is copied over SSH as the
  # admin user (dumont: `nix run .#deploy-dumont`). Locally built paths are
  # unsigned, so the copying user must be trusted by the nix daemon. Members
  # of wheel can already become root via sudo, so this grants nothing new.
  nix.settings.trusted-users = ["@wheel"];
}
