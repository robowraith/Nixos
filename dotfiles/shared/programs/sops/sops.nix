# /dotfiles/programs/sops/sops.nix
_: {
  # sops-nix configuration for home-manager
  sops = {
    defaultSopsFile = ../../../../secrets/shared.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      # No secrets defined yet for home-manager
      # The hm-secrets key in secrets.yaml is null
      # Uncomment and configure when you have actual secrets
      # "example-secret" = {
      #   sopsFile = ../../../secrets.yaml;
      #   key = "hm-secrets/example";
      # };
    };
  };
}
