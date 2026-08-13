{
  config,
  lib,
  pkgs,
  ...
}: let
  # Runs as root from sudo's PAM auth stack, right before pam_unix asks for the
  # password. Marks the terminal window that is about to show the prompt as
  # urgent in HerbstluftWM (red border). HerbstluftWM ignores urgency on the
  # focused window, so this only has an effect when you are looking elsewhere.
  #
  # The flag clears itself: the terminal drops the WM_HINTS urgency bit when it
  # regains focus and HerbstluftWM picks that up.
  markWindowUrgent = pkgs.writeShellScript "sudo-mark-window-urgent" ''
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.gnused pkgs.procps pkgs.util-linux pkgs.herbstluftwm]}

    [ "''${PAM_TYPE:-}" = "auth" ] || exit 0

    # Read a single variable out of another process' environment.
    getenv() {
      tr '\0' '\n' < "/proc/$1/environ" 2>/dev/null | sed -n "s/^$2=//p" | head -n1
    }

    # This script's parent is the process driving PAM, i.e. sudo itself, so its
    # environment is the caller's and carries WINDOWID. Processes on the tty
    # PAM reports are the fallback for cases where that does not hold.
    candidates="$PPID"
    pam_tty="''${PAM_TTY:-}"
    pam_tty="''${pam_tty#/dev/}"
    if [ -n "$pam_tty" ]; then
      candidates="$candidates $(ps -t "$pam_tty" -o pid= 2>/dev/null)"
    fi

    for pid in $candidates; do
      windowid=$(getenv "$pid" WINDOWID)
      case "''${windowid:-x}" in
        *[!0-9]*) continue ;;
      esac

      display=$(getenv "$pid" DISPLAY)
      [ -n "$display" ] || continue

      owner=$(stat -c %U "/proc/$pid" 2>/dev/null) || continue
      [ -n "$owner" ] || continue

      xauthority=$(getenv "$pid" XAUTHORITY)
      if [ -n "$xauthority" ]; then
        set -- DISPLAY="$display" XAUTHORITY="$xauthority"
      else
        set -- DISPLAY="$display"
      fi

      # Bounded and detached: the password prompt must never wait on X.
      timeout 2 runuser -u "$owner" -- env "$@" \
        herbstclient set_attr "clients.$(printf '0x%x' "$windowid").urgent" true \
        >/dev/null 2>&1 &
      break
    done

    exit 0
  '';
in {
  security.pam.services.sudo.rules.auth.mark-window-urgent = {
    # Must run before pam_unix prompts for the password.
    order = config.security.pam.services.sudo.rules.auth.unix.order - 100;
    # optional: a failing or missing script never blocks authentication.
    control = "optional";
    modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
    args = ["quiet" "${markWindowUrgent}"];
  };
}
