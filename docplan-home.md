# Documentation Plan — Home NixOS Setup

> Draft v1 — to be refined.

## Goal

A lightweight `docs/` structure that captures what the repo cannot express.
Nix is declarative, so for migrated hosts the flake *is* the config state;
documentation covers only the rest: hosts not yet migrated, external/mutable
state (data, DNS, mail, backups), in-flight migrations, design rationale, and
operational procedures.

It should:
- Give AI assistants a dense, single-read "state of the world" file (`STATE.md`)
- Give humans browsable rationale, a fleet reference, and runbooks
- Stay maintainable for a single operator — convention over automation
- Not duplicate what CLAUDE.md already covers (conventions, commands, layout)

## File structure

```
docs/
├── STATE.md            # AI-primary: migration status, external state, known issues
├── architecture.md     # Human-primary: rationale and design decisions
├── hosts.md            # Fleet reference table (incl. not-yet-migrated hosts)
└── runbooks/
    ├── migrate-host.md         # generic NixOS migration procedure
    ├── new-host.md             # add host to flake (expand CLAUDE.md steps w/ troubleshooting)
    ├── secrets.md              # sops key lifecycle: new host key, rotation, recovery
    ├── rollback-recovery.md    # broken rebuild, boot-menu rollback, remote host bricked
    └── <service>.md            # per stateful service as they migrate (mailcow, nextcloud, emby, backups)
```

## File contents

### `docs/STATE.md` — AI session-start read

Dense, fact-only, <150 lines. Covers:

- **Fleet one-liners** — hostname, role, user, NixOS? yes/no, notable stateful services.
- **Migration status** — which hosts are pending (stella, wintermute, neuromancer), current phase per host, blockers.
- **External / mutable state** — where data lives outside the repo: mail (mailcow), Nextcloud data, Emby library, ZFS pools, backup targets and directions, DNS/domains.
- **Network notes** — home LAN layout, VPS reachability, SSH/firewall assumptions.
- **Known issues / accepted debt** — intentional deviations (e.g. version pins, overlay workarounds and why).
- **Doc-of-record boundaries** — one line: repo = config truth for NixOS hosts; STATE.md = everything else.

Does NOT contain: conventions, commands, module layout (owned by CLAUDE.md), rationale (architecture.md).

### `docs/architecture.md` — rationale

- Why flakes + dendritic structure, why hostgroups/usergroups cascade.
- Why nixpkgs branch X (**note: README says unstable, CLAUDE.md says 25.11 — resolve this drift while writing**), why Chaotic-Nyx / Cachix, why the vicinae no-follows rule.
- Secrets design: sops-nix + age, key placement.
- Server architecture once migrated: what runs on wintermute vs neuromancer and why, backup topology.
- Theming (Stylix) and other cross-cutting choices.

Updated only on structural change.

### `docs/hosts.md` — fleet table

Move/expand the README systems table here: hostname, type, location, primary user, OS (NixOS/other), hostgroups, stateful services, migration status. README keeps a short intro and links to `docs/`.

### `docs/runbooks/` — procedures

English prose, step-by-step, each with a troubleshooting section and links to relevant flake paths. Priority order:

1. `migrate-host.md` — the generic playbook for moving a machine to this flake (hardware-config, secrets key, data migration, cutover, rollback plan). Highest value while 3 hosts are pending.
2. `rollback-recovery.md` — most error-prone moment; includes remote-host (neuromancer VPS) recovery where boot-menu access is nontrivial.
3. `secrets.md` — sops key lifecycle.
4. `new-host.md` — expands the CLAUDE.md 4-step list with real troubleshooting.
5. Per-service runbooks — written *during* each service migration (mailcow backup/restore first; mail is the highest-stakes stateful service).

Module-level documentation stays in the `.nix` files themselves: non-obvious
modules get a short header comment; no per-program README files.

## Existing file edits

- **CLAUDE.md** — add after Architecture:
  ```markdown
  ## System state reference
  For fleet status, active migrations, external state, and known issues, read
  `docs/STATE.md` at session start. Rationale and procedures: `docs/`.
  ```
- **README.md** — trim to intro + principles; fleet table moves to `docs/hosts.md`; fix the nixpkgs-branch drift.

## Maintenance

Convention over automation. One non-blocking pre-commit warning (the repo
already runs pre-commit hooks): if `system/hosts/` or `flake.nix` changed but
`docs/STATE.md` did not, print a reminder — never fail the commit.

| Document | Update when |
|---|---|
| `STATE.md` | Host migrated/added/removed, service moved, migration phase done, known issue resolved |
| `architecture.md` | Structural change (new host class, network redesign, input strategy change) |
| `hosts.md` | Host added/removed/repurposed, migration status change |
| `runbooks/*.md` | Procedure changes; new stateful service migrates |

## Phases

Each phase ships real content, not skeletons.

| Phase | Content | Notes |
|---|---|---|
| 1 | `docs/STATE.md` + CLAUDE.md pointer + pre-commit warning | Highest ROI; do first |
| 2 | `docs/hosts.md` + `docs/architecture.md` + README trim/drift-fix | Depends on 1 |
| 3 | Runbooks 1–4 (migrate, rollback, secrets, new-host) | Depends on 1 |
| 4 | Per-service runbooks | Written incrementally with each server migration |

## Out of scope

- Per-program-folder READMEs.
- Auto-generating docs from Nix evaluation.
- Documenting anything derivable from the flake itself.

## Verification

1. `STATE.md` < 150 lines, single read.
2. A fresh AI session with CLAUDE.md + STATE.md can answer "what is the state of each host and what's in flight?" without asking.
3. Pre-commit warning fires on host changes without a STATE.md touch, never blocks.
