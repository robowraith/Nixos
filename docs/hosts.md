# Hosts

Fleet reference. The flake (`system/hosts/`) is the configuration truth for
NixOS hosts; this table adds what the flake cannot express — hosts not yet
migrated, their current state, and migration order.

This repo is public: no IPs, FQDNs, or domains in this file.

| Host | Type | Location | User | Current OS | Hostgroups | Stateful services | Migration |
|---|---|---|---|---|---|---|---|
| **reason** | Desktop | home LAN | `joachim` | NixOS | desktop, home, mine | — | done |
| **deepthought** | Laptop (work) | mobile | `jhoss` | NixOS | desktop, home, mine | — | done |
| **dumont** | Server (Dell Wyse 3040) | home LAN | `yori` | NixOS | server | Pi-hole v6: LAN DHCP + primary DNS | done (new host) |
| **wintermute** | Server | home LAN | `dixie` | Ubuntu Server | — | Emby, Duplicati, Pi-hole v6 standby (k3s); Samba file server | pending (1st) |
| **neuromancer** | VPS | Hetzner | `case` | Ubuntu Server | — | Mailcow, Nextcloud, Traefik (Docker) | pending (2nd) |
| **stella** | Laptop | home LAN | `iris` | KDE neon | — | — | pending (3rd) |

## Pending migrations

Order: wintermute → neuromancer → stella. None started.

### wintermute

Homelab server. Emby and Duplicati run on k3s; Samba serves files directly on
the host. Pi-hole is no longer its job (see dumont below): it only keeps a
Pi-hole v6 pod as secondary DNS and dumont's cold DHCP standby. Migration must preserve the Emby library, Samba shares,
and Duplicati backup configuration/history. Target platform for the
containerized services (keep k3s vs. native NixOS modules vs.
`oci-containers`): **TBD** — to be decided in the migration runbook.

The Pi-hole standby's manifests and runbook are in
[`wintermute/pihole/`](wintermute/pihole/README.md), its history in
[`wintermute/pihole/history.md`](wintermute/pihole/history.md). Findings that
feed the platform decision:

- Pi-hole needs the real LAN interface (DHCP, client IPs in the query log,
  IPv6 on a rotating provider prefix). Running it in the pod network took
  three relay/proxy shims that drifted and broke; host networking removed all
  of them. Whatever the target platform, Pi-hole should be host-networked.
- The standby pod is rendered from dumont's NixOS config (`v6.nix`), so after
  the reinstall it can become a native `services.pihole-ftl` from the same
  module (see Planned: secondary DNS).
- The router's own secondary DNS points at wintermute's Pi-hole, so
  migration downtime there degrades, but no longer breaks, LAN DNS.
- Traefik's ServiceLB owns :80/:443 on the host; Pi-hole's web UI sits on
  :8080 behind it. A migration must keep or replace that ingress layer.
- Cluster objects used to exist only in the cluster. The Pi-hole ones are now
  in the repo; Emby and Duplicati are not yet.
- The iLO 4 has a static address that must never collide with dumont's; check
  it (`ipmitool lan print 2`) before plugging in its cable.

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

## dumont

Dell Wyse 3040 (Atom x5-Z8350, 2 GB RAM, 8 GB eMMC), headless, static
address. The LAN's DHCP server and primary DNS since 2026-10-26: Pi-hole v6 on
the native NixOS modules (`system/hosts/dumont/modules/pihole.nix`). Planned
and built in the OpenSpec change `add-dumont-pihole-host` (under
`openspec/changes/archive/` once archived).

- **Config is declarative.** Settings, blocklists and the allowlist are in the
  flake; the web UI cannot change them. The device inventory (DHCP
  reservations with MACs, local DNS records) lives only in
  `secrets/dumont.yaml`, because this repo is public.
- **Secrets:** per-host sops key derived from its SSH host key
  (`fleet.sops.perHostKey`); it never holds the shared age key.
- **No Home Manager, nothing built on the box.** Deployed from a desktop with
  `nix run .#deploy-dumont`, which refuses unclean or unpushed trees, activates
  with `test`, health-checks DNS/blocking/SSH/FTL and only then switches
  (`docs/runbooks/dumont-deploy.md`). Install: `docs/runbooks/dumont-install.md`.
- **DHCP** hands out dumont and wintermute as DNS servers, 72 h leases.
  wintermute is a manual cold standby with 1 h leases; never run both DHCP
  servers at once (`docs/runbooks/dhcp-failover.md`).
- **Pi-hole notes that moved here from wintermute:** the router forwards its
  own DNS to Pi-hole (primary dumont, secondary wintermute), so clients that
  use the router's IPv6 DNS are filtered too. Its DNS rebind protection needs
  an exception for the LAN domain, or local names vanish via that path.
- **Temporary pin:** Pi-hole (FTL 6.9) and its NixOS module come from
  `nixpkgs-unstable` for a security fix; revert at 26.11 (comment in
  `pihole.nix`).

## Planned

Follow-ups from `add-dumont-pihole-host`, recorded here so they survive its
archiving. None started.

### Pi-hole monitoring from wintermute

dumont is now the single point of failure for DHCP and the primary DNS, and
nothing watches it. Run checks from wintermute (a different host than the one
watched, so "dumont is down" can be reported), not from reason (usually off).
Checks, already verified by hand, every ~2 min:

- dumont's DNS resolves a normal name (e.g. `example.com`) to an address
- dumont's DNS answers an ad domain (e.g. `doubleclick.net`) with `0.0.0.0`
- the router's DNS answers the same ad domain with `0.0.0.0` (catches a router
  reset or firmware update that silently stops forwarding to Pi-hole)

Alert once per change of state (broken, which check, recovered), not every
run. Open questions:

- **Alert channel:** ntfy, e-mail (the mail server on neuromancer is being
  retired), or a Telegram/Signal bot. Must not depend on the LAN's DNS (use an
  IP or a public resolver).
- **Platform:** k3s CronJob now, or a systemd timer after wintermute's NixOS
  reinstall.
- **External dead-man's switch** (healthchecks.io-style), to also cover
  "wintermute is down".
- **Extra checks:** DHCP (FTL listening on :67) and gravity freshness.

### Secondary DNS on NixOS

Mostly done: since 2026-11-24 wintermute runs Pi-hole v6 rendered from
dumont's config (same upstreams, lists, inventory; DHCP configured but off).
Left: after wintermute's NixOS reinstall, replace the k3s pod with native
`services.pihole-ftl` from the same module and the same sops inventory, with
the standby differences listed in `docs/wintermute/pihole/README.md`
("Pi-hole v6").

### Deploy dumont from wintermute

Once wintermute runs NixOS it needs only the flake checkout and a key to push
closures; the deploy app already addresses dumont by IP. That makes dumont
deployable when both desktops are off.

### HTTPS for dumont's web UI

v6 can serve TLS on :443 with its own certificate. Worth it only if the UI is
ever reached from outside the LAN, or once a LAN CA exists.

### Unattended updates for dumont

Deliberately none: dumont changes only through guarded deploys from a desktop.
Revisit if security updates lag because the desktops are often off.
