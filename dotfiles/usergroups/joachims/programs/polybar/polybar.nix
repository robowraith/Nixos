{
  pkgs,
  lib,
  ...
}: let
  hlwm_tags = pkgs.writeShellScript "hlwm_tags.sh" ''
    # Multi monitor support. Needs MONITOR environment variable to be set for each instance of polybar
    # If MONITOR environment variable is not set this will default to monitor 0
    # Check https://github.com/polybar/polybar/issues/763
    MON_IDX="0"
    mapfile -t MONITOR_LIST < <(${pkgs.polybar}/bin/polybar --list-monitors | ${pkgs.coreutils}/bin/cut -d":" -f1)
    for ((i = 0; i < ''${#MONITOR_LIST[@]}; i++)); do
      [[ ''${MONITOR_LIST[''${i}]} == "$MONITOR" ]] && MON_IDX="$i"
    done

    ${pkgs.herbstluftwm}/bin/herbstclient --idle "tag_*" 2>/dev/null | {

      while true; do
        # Read tags into $tags as array
        IFS=$'\t' read -ra tags <<<"$(${pkgs.herbstluftwm}/bin/herbstclient tag_status "''${MON_IDX}")"
        {
          for i in "''${tags[@]}"; do
            # Read the prefix from each tag and render them according to that prefix
            case ''${i:0:1} in
            '.')
              # the tag is empty
              ;;
            ':')
              # the tag is not empty
              ;;
            '+')
              # the tag is viewed on the specified MONITOR, but this monitor is not focused.
              ;;
            '#')
              # the tag is viewed on the specified MONITOR and it is focused.
              ;;
            '-')
              # the tag is viewed on a different MONITOR, but this monitor is not focused.
              ;;
            '%')
              # the tag is viewed on a different MONITOR and it is focused.
              ;;
            '!')
              # the tag contains an urgent window
              ;;
            esac

            # focus the monitor of the current bar before switching tags
            echo "%{A1:${pkgs.herbstluftwm}/bin/herbstclient focus_monitor ''${MON_IDX}; ${pkgs.herbstluftwm}/bin/herbstclient use ''${i:1}:}  ''${i:1}  %{A -u -o F- B-}"
          done

          # reset foreground and background color to default
          echo "%{F-}%{B-}"
        } | ${pkgs.coreutils}/bin/tr -d "\n"

        echo

        # wait for next event from herbstclient --idle
        read -r || break
      done
    } 2>/dev/null
  '';
in {
  services.polybar = {
    enable = true;
    # Polybar is launched directly from herbstluftwm's screen_setup.fish so it
    # inherits the per-profile POLYBAR_WIDTH/POLYBAR_OFFSET_X env vars (the
    # systemd service's environment can't see them). script is unused.
    script = "true";
    config = ./config.ini;
    package = pkgs.polybar;
  };

  # Don't auto-start the bar from the systemd service; screen_setup.fish owns
  # launching it with the right geometry per autorandr profile.
  systemd.user.services.polybar.Install.WantedBy = lib.mkForce [];

  xdg.configFile = {
    "polybar/scripts/hlwm_tags.sh".source = hlwm_tags;
  };
}
