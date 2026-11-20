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

Pi-hole (DHCP + DNS for the whole LAN) was moved to the host network in
2026-10; its k3s manifests, cutover runbook and rollback are in
[`wintermute/pihole/`](wintermute/pihole/README.md). Findings that feed the
platform decision:

- Pi-hole needs the real LAN interface (DHCP, client IPs in the query log,
  IPv6 on a rotating provider prefix). Running it in the pod network took
  three relay/proxy shims that drifted and broke; host networking removed all
  of them. Whatever the target platform, Pi-hole should be host-networked.
- Pi-hole stays on the v5 image on purpose (a v6 upgrade attempt was rolled
  back). Its gravity database had been left in the v6 schema and was rebuilt.
- The router forwards its own DNS to Pi-hole, so Pi-hole is a single point of
  failure for LAN name resolution: migration downtime is a full DNS outage.
- Traefik's ServiceLB owns :80/:443 on the host; Pi-hole's web UI sits on
  :8080 behind it. A migration must keep or replace that ingress layer.
- Cluster objects used to exist only in the cluster. The Pi-hole ones are now
  in the repo; Emby and Duplicati are not yet.

#### Planned: LAN binary cache (added after the NixOS reinstall)

Once wintermute runs NixOS, it becomes the fleet's Nix cache, so each store
path is downloaded from upstream once instead of once per host. Wintermute is
the right place for it because it is always on, and reason usually is not.

- **No full mirror.** cache.nixos.org holds hundreds of TB, and even a single
  x86_64-linux channel snapshot is several TB that every channel bump largely
  replaces. A git mirror of nixpkgs (~5 GB) would not help: the source tree is
  not what gets downloaded repeatedly.
- **Pull-through caching proxy instead.** Preferred: `ncps` (NixOS module, LRU
  eviction with a size cap, re-signs with its own key that clients add to
  `trusted-public-keys`). Fallback: nginx `proxy_cache` in front of
  cache.nixos.org (needs no key because upstream signatures pass through, but
  evicts less cleverly). Check the module options at implementation time.
- **Size budget: 100–200 GB, capped.** The fleet only pulls its own system
  closures (a few GB to a few tens of GB each, largely shared between reason
  and deepthought), so a few generations of every host fit comfortably.
- **Clients** (`system/shared`, or `home` for LAN-only hosts): list wintermute
  first in `substituters` with cache.nixos.org as the fallback, and set a short
  `connect-timeout`. deepthought leaves the LAN, so it must not stall on rebuilds
  when wintermute can't be reached.
- **Expected benefit is modest.** reason is mostly off, so the two desktops rarely
  fetch the same update at the same time. dumont gets its closures pushed from a
  desktop during remote deploys, so it gains almost nothing. Most hits will come
  from deepthought.
- **Possible follow-up: Attic or Harmonia for self-built paths.** Overlay
  packages (herbstluftwm patch, freac fix) and anything else missing from
  cache.nixos.org are currently compiled on each desktop. Building them once on
  wintermute and serving them from the cache may save more than the proxy does.
  Not part of the first step.

### neuromancer

Hetzner VPS. Mailcow, Nextcloud, and Traefik run on Docker. Highest-stakes
migration: live mail service and remote recovery (no physical boot-menu
access). Migrated second, after lessons from wintermute. Target platform:
**TBD** — to be decided in the migration runbook.

### stella

Daily-driver laptop, currently KDE neon. No stateful services; local user data
only. Simplest migration — config largely reusable from the existing desktop
hosts. Migrated last.
