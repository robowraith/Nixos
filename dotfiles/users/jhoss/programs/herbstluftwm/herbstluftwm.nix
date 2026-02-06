_: {
  # Write the autostart config to XDG config
  xdg.configFile = {
    "herbstluftwm/autostart" = {
      source = ./autostart;
      executable = true;
      force = true;
    };
    "herbstluftwm/conf.d/screen_setup.fish" = {
      source = ./conf.d/screen_setup.fish;
    };
    "herbstluftwm/bin/setup_main_workspace.fish" = {
      source = ./bin/setup_main_workspace.fish;
    };
    "herbstluftwm/bin/setup_ansible_workspace_with_vscode.fish".source = ./bin/setup_ansible_workspace_with_vscode.fish;
    "herbstluftwm/bin/setup_ansible_workspace_with_helix.fish". source = ./bin/setup_ansible_workspace_with_helix.fish;
    "herbstluftwm/bin/setup_nixos_workspace_with_vscode.fish". source = ./bin/setup_nixos_workspace_with_vscode.fish;
  };
}
