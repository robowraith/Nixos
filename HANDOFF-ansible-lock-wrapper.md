# Handoff: fish lock wrappers for `ansible-playbook` and `ansible`

## Task
Add two fish functions to `dotfiles/users/jhoss/programs/fish/functions.nix` (home-manager fish config, see existing `bwu` entry there for style). Purpose: temporary stopgap to stop multiple parallel git-worktree sessions (each running Ansible against Vagrant or Production) from executing concurrently. Global lockfiles in `/tmp` so it applies across all worktrees/shells on this machine, not per-repo.

This is throwaway/temporary — Joachim is building a proper `ansible-playbook` wrapper (project "wrap", see `~/code/ansible` conversation history) that will handle this at the production level. This fish-level lock is just to survive until that lands.

## Functions to add

```fish
programs.fish.functions = {
  # ... existing bwu entry stays ...

  ansible-playbook = ''
    flock -n /tmp/ansible-playbook.lock command ansible-playbook $argv
    or begin
      echo "Another ansible-playbook run is active — waiting..." >&2
      flock /tmp/ansible-playbook.lock command ansible-playbook $argv
    end
  '';

  ansible = ''
    flock -n /tmp/ansible-adhoc.lock command ansible $argv
    or begin
      echo "Another ansible run is active — waiting..." >&2
      flock /tmp/ansible-adhoc.lock command ansible $argv
    end
  '';
};
```

Notes:
- Separate lockfiles for `ansible-playbook` vs `ansible` (ad-hoc) — deliberately not shared, since ad-hoc commands are generally lower-risk/faster than playbook runs and serializing them together would be overly conservative. Confirm with Joachim if he wants them merged into one lock instead.
- `-n` (non-blocking) first attempt gives immediate feedback that something else is running; falls back to blocking `flock` so the second invocation just waits its turn instead of failing.
- Uses `command ansible-playbook` / `command ansible` inside to avoid the function recursing into itself.
- Requires `flock` (util-linux) available in PATH — check it's present in the fish environment or add it to packages if not.

## Verification
- `nixos-rebuild switch` (or whatever this flake's apply command is) then open a new fish shell, confirm `type ansible-playbook` shows the function, and manually test two concurrent invocations serialize.
