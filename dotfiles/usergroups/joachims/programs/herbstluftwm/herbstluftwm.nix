{pkgs, ...}: {
  # Install HerbstluftWM
  home.packages = [pkgs.herbstluftwm];

  # Enable X session for HerbstluftWM
  xsession = {
    enable = true;
    windowManager.command = "${pkgs.herbstluftwm}/bin/herbstluftwm";
  };

  # The hlwm autostart owns startup order: it waits for KeePassXC to be
  # unlocked before starting apps that need the secret service. XDG autostart
  # (pulled in by hm-graphical-session.target) would bypass that, so programs
  # must not drop their own entries (e.g. Nextcloud's "Launch on startup").
  xdg.autostart.readOnly = true;

  # Write the autostart config to XDG config
  xdg.configFile = {
    # Overwritten in user specific configs
    #   "herbstluftwm/autostart" = {
    #     source = ./autostart;
    #     executable = true;
    #     force = true;
    #   };

    # Copy other configuration files and scripts
    # "herbstluftwm/bin" = {
    #   source = ./bin;
    #   recursive = true;
    # };
    "herbstluftwm/bin/fullscreen_window.fish".source = ./bin/fullscreen_window.fish;
    "herbstluftwm/bin/switch_tag_or_cycle.fish".source = ./bin/switch_tag_or_cycle.fish;
    "herbstluftwm/bin/setup_nixos_workspace_with_helix.fish".source = ./bin/setup_nixos_workspace_with_helix.fish;
    "herbstluftwm/bin/mark_window_urgent.fish".source = ./bin/mark_window_urgent.fish;
    "herbstluftwm/bin/jump_urgent_or_back.fish".source = ./bin/jump_urgent_or_back.fish;
    "herbstluftwm/bin/toggle_audio_profile.fish".source = ./bin/toggle_audio_profile.fish;
    "herbstluftwm/conf.d/keybindings.fish".source = ./conf.d/keybindings.fish;
    "herbstluftwm/conf.d/rules.fish".source = ./conf.d/rules.fish;
    "herbstluftwm/conf.d/tags.fish".source = ./conf.d/tags.fish;
    "herbstluftwm/conf.d/theme.fish".source = ./conf.d/theme.fish;
  };
}
