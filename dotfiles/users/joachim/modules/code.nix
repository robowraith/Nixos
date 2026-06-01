{
  pkgs,
  lib,
  ...
}: {
  home.activation.cloneCodeRepos = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p "$HOME/code"
    export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh"

    # QMK Firmware (GitHub blocks port 22; use port 443 via ssh.github.com)
    QMK_DIR="$HOME/code/qmk"
    if [ ! -d "$QMK_DIR/.git" ]; then
      QMK_TMPKEY=$(${pkgs.coreutils}/bin/mktemp)
      ${pkgs.coreutils}/bin/cp "$HOME/Nextcloud/Keys/ssh_privat/id_ed25519" "$QMK_TMPKEY"
      chmod 600 "$QMK_TMPKEY"
      GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i $QMK_TMPKEY -o StrictHostKeyChecking=no" \
        $DRY_RUN_CMD ${pkgs.git}/bin/git clone \
          ssh://git@ssh.github.com:443/robowraith/qmk_firmware.git "$QMK_DIR" \
        || echo "Warning: qmk clone failed, will retry on next activation"
      rm -f "$QMK_TMPKEY"
    fi
  '';
}
