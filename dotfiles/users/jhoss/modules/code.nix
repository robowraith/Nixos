{
  pkgs,
  lib,
  ...
}: {
  home.activation.cloneCodeRepos = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p "$HOME/code"
    export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh"

    # Ansible
    ANSIBLE_DIR="$HOME/code/ansible"
    if [ ! -d "$ANSIBLE_DIR/.git" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone git@git.42he.com:devops/ansible.git "$ANSIBLE_DIR"
    fi

    # Puppet Files
    PUPPET_DIR="$HOME/code/puppet_files"
    if [ ! -d "$PUPPET_DIR/.git" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone git@git.42he.com:devops/puppet_files.git "$PUPPET_DIR"
    fi
  '';
}
