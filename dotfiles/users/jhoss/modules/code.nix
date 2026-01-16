{ pkgs, lib, ... }:

{
  home.activation.cloneAnsibleRepo = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p "$HOME/code"
    ANSIBLE_DIR="$HOME/code/ansible"
    if [ ! -d "$ANSIBLE_DIR/.git" ]; then
      export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh"
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone git@git.42he.com:devops/ansible.git "$ANSIBLE_DIR"
    fi
  '';
}
