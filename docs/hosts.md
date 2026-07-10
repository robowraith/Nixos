# Hosts

Fleet reference. The flake (`system/hosts/`) is the configuration truth for
NixOS hosts; this table adds what the flake cannot express — hosts not yet
migrated, their current state, and migration order.

This repo is public: no IPs, FQDNs, or domains in this file.

| Host | Type | Location | User | Current OS | Hostgroups | Stateful services | Migration |
|---|---|---|---|---|---|---|---|
| **reason** | Desktop | home LAN | `joachim` | NixOS | desktop, home, mine | — | done |
| **deepthought** | Laptop (work) | mobile | `jhoss` | NixOS | desktop, home, mine | — | done |
| **wintermute** | Server | home LAN | `dixie` | Ubuntu Server | — | Emby, Duplicati, Pi-hole (k3s); Samba file server | pending (1st) |
| **neuromancer** | VPS | Hetzner | `case` | Ubuntu Server | — | Mailcow, Nextcloud, Traefik (Docker) | pending (2nd) |
| **stella** | Laptop | home LAN | `iris` | KDE neon | — | — | pending (3rd) |

## Pending migrations

Order: wintermute → neuromancer → stella. None started.

### wintermute

Homelab server. Emby, Duplicati, and Pi-hole run on k3s; Samba serves files
directly on the host. Migration must preserve the Emby library, Samba shares,
and Duplicati backup configuration/history. Target platform for the
containerized services (keep k3s vs. native NixOS modules vs.
`oci-containers`): **TBD** — to be decided in the migration runbook.

### neuromancer

Hetzner VPS. Mailcow, Nextcloud, and Traefik run on Docker. Highest-stakes
migration: live mail service and remote recovery (no physical boot-menu
access). Migrated second, after lessons from wintermute. Target platform:
**TBD** — to be decided in the migration runbook.

### stella

Daily-driver laptop, currently KDE neon. No stateful services; local user data
only. Simplest migration — config largely reusable from the existing desktop
hosts. Migrated last.
