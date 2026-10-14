# Proposal

## Why

Pi-hole is the only DNS and DHCP server on the home LAN, and it runs on wintermute's k3s, mixed in with Emby,
Duplicati and Samba. Its v5 config lives as imperative state inside the cluster. That has repeatedly drifted out of
sync with what was intended: stale shims, reservations that were never loaded, a frozen gravity DB, and a
hand-placed KSK-2024 trust anchor. Any maintenance on wintermute is a LAN-wide DNS outage. A dedicated Dell Wyse 3040
thin client (Atom x5-Z8350, 2 GB RAM, 8 GB eMMC) is now available. Moving Pi-hole onto it as a NixOS host makes the
DNS/DHCP configuration declarative and reviewable, and separates it from wintermute ahead of wintermute's own NixOS
migration.

## What Changes

- **New NixOS host `dumont`** (user `yori`): the Wyse 3040, headless, static `192.168.1.2`. It is installed once
  with nixos-anywhere + disko and from then on deployed only from reason or deepthought (later wintermute). Nothing
  is ever built on the box itself.
- **Pi-hole v6 on the native NixOS modules** (`services.pihole-ftl` / `services.pihole-web`), replacing the pinned
  v5 container image. Settings, blocklists and the allowlist are declarative. The device inventory (DHCP reservations
  with MACs, local DNS records) is kept in sops so it stays out of this public repo. The web UI is no longer a way
  to change configuration.
- **Flake refactor:** `system/shared` is reduced to what every machine needs. Docker, the CachyOS kernel/scx,
  Plymouth, Stylix and fonts move into the desktop layer, and a new `server` hostgroup is added. `mkHost` can build a
  host without Home Manager and with a per-host `stateVersion`. reason and deepthought **must not change** as a
  result.
- **Per-host sops keys:** dumont decrypts only `secrets/dumont.yaml`, using an age identity derived from its SSH host
  key. It never holds the shared age key. reason and deepthought keep the shared key.
- **Guarded deploy command** for dumont: activate with `test`, health-check DNS/blocking/SSH/FTL from the deploying
  machine, then `switch` or automatically revert. A power cycle is the last-resort rollback.
- **Cutover from wintermute** in phases: dumont DNS-only → a few days' trial run with reason/deepthought → DHCP moved
  over with shortened leases while wintermute's DNS keeps answering → wintermute's Pi-hole scaled to 0 → cleanup on
  wintermute after about two weeks of stable running.
- **Docs:** install and cutover/rollback runbooks, `docs/hosts.md` updated. Follow-ups that are out of scope are
  recorded for later pickup.

## Capabilities

### New Capabilities

- `lan-dns-dhcp`: DNS resolution, ad blocking, DNSSEC validation and DHCP for the home LAN, served by dumont. This
  covers keeping the device inventory private and a cutover that never leaves two DHCP servers running or clients
  without a reachable DNS server.
- `host-deployment`: how a fleet host is installed and changed remotely: built off-host, guarded activation with
  health checks and automatic revert, and rebuilds that stay the user's job.
- `host-profiles`: what a server-class host does and does not contain compared with a desktop, and how secrets
  are scoped per host.

### Modified Capabilities

None. This is the repo's first OpenSpec change, so there are no existing specs to modify.

## Impact

- `flake.nix`: `mkHost` parameters (Home Manager optional, `stateVersion`), new `dumont` host, deploy app.
- `system/shared/**`, `system/hostgroups/desktop/**`, new `system/hostgroups/server/`, new `system/hosts/dumont/`.
- `.sops.yaml`, new `secrets/dumont.yaml`. `system/shared/modules/sops.nix` becomes per-host.
- wintermute (live, outside the flake): Pi-hole DHCP lease time, DHCP off, deployment scaled to 0, later removal of
  the Pi-hole objects, the `.4` secondary address and the KSK hack.
- Speedport: upstream DNSv4/DNSv6 repointed to dumont.
- Docs: `docs/hosts.md`, new runbooks, `docs/wintermute/pihole/` marked historical after cleanup.
