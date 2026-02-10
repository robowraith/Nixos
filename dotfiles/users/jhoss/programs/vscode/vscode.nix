{
  pkgs,
  lib,
  ...
}: {
  programs.vscode = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-extensions;
      [
        redhat.ansible
        redhat.vscode-yaml
        samuelcolvin.jinjahtml
        ms-vscode-remote.remote-containers
      ]
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "vscode-helix-emulation";
          publisher = "jasew";
          version = "0.7.0";
          sha256 = "1diwv1q1z8kkx9v0jzzfb5sa5v9825dx872di9k0px66fmb8i341";
        }
      ];

    profiles.default.userSettings = {
      # Font configuration
      "editor.fontFamily" = lib.mkForce "'FiraCode Nerd Font', 'Droid Sans Mono', 'monospace', monospace";
      "editor.fontLigatures" = true;

      # Disable RedHat telemetry
      "ansible.lightspeed.enabled" = false;
      "redhat.telemetry.enabled" = false;

      # General settings
      "workbench.startupEditor" = "none";
      "remote.autoForwardPortsSource" = "hybrid";
    };
  };
}
