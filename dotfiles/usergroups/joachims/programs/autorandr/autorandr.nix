_: {
  programs.autorandr = {
    enable = true;

    hooks = {
      postswitch = {
        "autorandr_variables" = ''
          # Wait for X to settle
          sleep 1

          /usr/bin/env fish -c "set -Ux AUTORANDR_CURRENT_PROFILE $AUTORANDR_CURRENT_PROFILE"
          /usr/bin/env fish -c "set -Ux AUTORANDR_CURRENT_PROFILES $AUTORANDR_CURRENT_PROFILES"
          /usr/bin/env fish -c "set -Ux AUTORANDR_PROFILE_FOLDER $AUTORANDR_PROFILE_FOLDER"
          /usr/bin/env fish -c "set -Ux AUTORANDR_MONITORS $AUTORANDR_MONITORS"

          dunstify-send -i display "Display profile" "$AUTORANDR_CURRENT_PROFILE"

          exit 0
        '';
      };
    };
  };

  # Systemd service to auto-detect and switch on login/resume
  systemd.user.services.autorandr = {
    Unit = {
      Description = "Autorandr execution hook";
      After = ["graphical-session-pre.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.autorandr}/bin/autorandr --change";
      RemainAfterExit = false;
    };

    Install.WantedBy = ["graphical-session.target"];
  };
}
