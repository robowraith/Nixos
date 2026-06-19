_: {
  programs.autorandr = {
    enable = true;

    hooks = {
      postswitch = {
        "autorandr_variables" = ''
          # Wait for X to settle
          sleep 1

          # -Ux: the exported-universal attribute is persisted to
          # fish_variables, so every later fish shell exports these into
          # its child scripts' environment (needed by herbstluftwm-start
          # scripts that read them as env vars).
          /usr/bin/env fish -c "set -Ux AUTORANDR_CURRENT_PROFILE $AUTORANDR_CURRENT_PROFILE"
          /usr/bin/env fish -c "set -Ux AUTORANDR_CURRENT_PROFILES $AUTORANDR_CURRENT_PROFILES"
          /usr/bin/env fish -c "set -Ux AUTORANDR_PROFILE_FOLDER $AUTORANDR_PROFILE_FOLDER"
          /usr/bin/env fish -c "set -Ux AUTORANDR_MONITORS $AUTORANDR_MONITORS"

          dunstify -i display "Display profile" "$AUTORANDR_CURRENT_PROFILE"

          exit 0
        '';
      };
    };
  };

  imports = [./systemd.nix];
}
