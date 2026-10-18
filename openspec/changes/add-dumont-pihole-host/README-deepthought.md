# Installation dumont — pickup on another machine

Copy of the OpenSpec change `add-dumont-pihole-host` from reason (updated 2026-10-18), including the parts that are
**not in git**:
- the current `proposal.md`, `design.md`, `tasks.md` and `specs/`; `tasks.md` has 13/30 tasks checked
- `HANDOFF.md`, the full state and next steps; **read this first**
- `baseline-drvpaths.txt`, the desktop drvPath baselines (the **last** entry per host is current)

In the repo these files live in `openspec/changes/add-dumont-pihole-host/`.

## Code

The implementation is pushed: `f90a5d3` "Add headless host dumont and split desktop config out of shared", rebased
onto the Zen kernel switch (`2e303f8`). A plain `git pull` brings it in. The earlier patch file in this folder is
obsolete and has been removed.

## Continue on deepthought

1. In `~/nixos`, run `git pull`.
2. Copy all files from this folder except this README into `~/nixos/openspec/changes/add-dumont-pihole-host/`,
   overwriting the committed versions. The copies here are newer.
3. `/opsx:apply add-dumont-pihole-host`. The next task is **6.1** (the `deploy-dumont` app). The user's part, 4.2
   (secrets), is described in HANDOFF.md.

Editing `secrets/dumont.yaml` needs the shared age key (root-only at `/var/lib/sops/age/keys.txt`), which
deepthought has too.
