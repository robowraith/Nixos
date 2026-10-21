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

    # Show or switch the Sentry MCP token mode (ro|rw); takes effect at the next Claude Code restart.
    sentry-mode = ''
      set -l d ~/.config/sentry-mcp
      if test (count $argv) -eq 0
          readlink $d/token | string replace 'token.' '''
          return
      end
      if not contains -- $argv[1] ro rw
          echo "usage: sentry-mode [ro|rw]" >&2
          return 2
      end
      if not test -f $d/token.$argv[1]
          echo "sentry-mode: $d/token.$argv[1] missing" >&2
          return 1
      end
      ln -sfn token.$argv[1] $d/token
      and echo "sentry-mcp: $argv[1] — restart Claude Code to pick it up"
    '';
  };
}
