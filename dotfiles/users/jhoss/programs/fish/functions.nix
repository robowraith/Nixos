{
  programs.fish.functions = {
    # Unlock Bitwarden and export the session key into the current shell.
    bwu = ''
      set -gx BW_SESSION (bw unlock --raw)
      and echo "Bitwarden unlocked."
    '';

    # Serialize concurrent ansible-playbook runs across worktrees/shells.
    ansible-playbook = ''
      flock -n /tmp/ansible-playbook.lock command ansible-playbook $argv
      or begin
        echo "Another ansible-playbook run is active — waiting..." >&2
        flock /tmp/ansible-playbook.lock command ansible-playbook $argv
      end
    '';

    # Serialize concurrent ansible ad-hoc runs across worktrees/shells.
    ansible = ''
      flock -n /tmp/ansible-adhoc.lock command ansible $argv
      or begin
        echo "Another ansible run is active — waiting..." >&2
        flock /tmp/ansible-adhoc.lock command ansible $argv
      end
    '';
  };
}
