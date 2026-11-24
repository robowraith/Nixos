# Pi-hole on wintermute: history (2024 – 2026-11)

Pi-hole ran DHCP and DNS for the home LAN on wintermute's k3s cluster until 2026-10-26, when dumont (Dell Wyse 3040,
NixOS, Pi-hole v6) took over. Since 2026-11-24 wintermute runs Pi-hole v6 only as the secondary DNS and dumont's
cold DHCP standby (see [README](README.md), "Pi-hole v6", and `docs/runbooks/dhcp-failover.md`).

This page keeps the findings that explain how it got there. Nothing here is a live procedure. It was folded in from a
local handoff file on 2026-11-24. MACs, IPv6 interface IDs and the ULA prefix were left out on purpose (public repo).

## Timeline

| Date | Event |
|---|---|
| 2024 | v5 pinned to `pihole/pihole:2024.07.0` (Pi-hole 5.18.3, FTL 5.25.2) after an earlier v6 upgrade broke something. The cause was forgotten. |
| 2026-05-04 | Another v6 upgrade attempt, rolled back. It left `gravity.db` at schema 20 (v6), which v5 cannot update. |
| 2026-08-10 | Drift bugs found and fixed (below). Architecture question opened: fix in place, or dedicated hardware. |
| 2026-10-03 | Option A done in place: `hostNetwork: true`, three shims deleted. IPv6 DNS bypass closed. Gravity rebuilt. |
| 2026-10-11 | Root KSK-2024 rollover. v5 ships only KSK-2017, so DNSSEC failed until a `trust-anchor` file was added (README). |
| 2026-10-14 | Option B wins anyway: Pi-hole moves to dumont, as v6 on the native NixOS module (OpenSpec change `add-dumont-pihole-host`). |
| 2026-10-22 | PHP RCE stopgap for the v5 web UI (README). |
| 2026-10-26 | Cutover: dumont is DHCP + primary DNS. wintermute's v5 stays as secondary DNS with DHCP off. |
| 2026-11-24 | wintermute's v5 replaced by v6 rendered from dumont's config (`v6.nix`). The PHP ConfigMap is deleted. |

## Why the pod-network setup kept breaking (2026-08)

FTL ran in the pod network. DHCP, IPv6 DNS and IPv4 DNS had to be carried in from the LAN by `pihole-dhcp-relay`,
`pihole-ipv6-proxy` and Traefik routes. `pihole-ip-watcher` patched the shims whenever the pod IP or the IPv6
prefix changed. Every one of these drifted:

- **DHCP reservations went inert.** A `dhcp-host` line in `04-pihole-static-dhcp.conf` takes effect only when FTL
  starts. It happened twice (reason in 2026-06, the SV08 printer in 2026-09), and each time a
  `rollout restart` fixed it. Explained on 2026-10-03: the v5 UI's static-lease **Add** button only appends to the
  file. Only the DHCP section's main **Save** button restarts FTL. SIGHUP does not re-read `dhcp-host`.
- **A duplicate `custom.list` entry** made `reason` resolve to two addresses (split-brain).
- **`pihole-ipv6-proxy` crash-looped for 90 days** (20,900+ restarts, unnoticed). Its Corefile had a bind address
  from an old provider prefix (Telekom rotates the delegated /64) and forwarded to a raw pod IP.
- **`pihole-ip-watcher` could not fix it.** It built its ConfigMap patch with `printf`, which turned `\n` into real
  newlines inside a JSON string, so every prefix rotation failed with `invalid character '\n' in string literal`.
- **An FTL restart took LAN DHCP down for ~10 min (2026-10-03).** The new pod IP was patched into the relay, but the
  relay Deployment used RollingUpdate. Both relay pods are hostNetwork and need :67, so the new one crash-looped
  while the old one relayed to the dead IP. Fixed by switching it to `strategy: Recreate`.
- **The UI could not enable Router Advertisements.** `PIHOLE_INTERFACE=eth0` was the pod's interface, which had
  only a link-local address, so the generator never wrote `enable-ra`.

Lesson that carried into dumont: **Pi-hole needs the real LAN interface.** Every shim around it is a drift source.

## Fix in place vs. dedicated hardware (2026-10)

- **Option A, in place:** `hostNetwork: true` on the same k3s and image. The port audit found only the shims'
  own :53/:67, plus Traefik's ServiceLB on :53/:80/:443 (iptables DNAT, invisible to `ss`), so the web UI moved to
  :8080. Done 2026-10-03, ~50 s DNS outage, all checks passed (README, "hostNetwork cutover").
- **Option B, own hardware:** HP T630 or Raspberry Pi 4 + USB SSD were weighed. It isolates the failure domain
  from Emby/Duplicati/Samba and host maintenance, for about €15/year more electricity (€0.25/kWh, ~7 W). A Pi
  must boot from SSD, not SD. In the end a Dell Wyse 3040 was used.
- Switching k3s for another Kubernetes distribution was ruled out: it costs more than A and gains nothing.
- B won on 2026-10-14, once a Wyse 3040 was available. The reasons (proposal of `add-dumont-pihole-host`): any
  maintenance on wintermute was a LAN-wide DNS outage, and v5's imperative in-cluster state kept drifting. A NixOS
  host makes the config declarative and gets Pi-hole off wintermute before its own NixOS migration.

## IPv6 DNS bypass (closed 2026-10-03)

Clients got the Speedport (`fe80::1`) as IPv6 DNS through its Router Advertisements, which bypassed Pi-hole. The
Speedport Smart 4 cannot change the DNS server it announces. Fix without a Pi-hole RA: enable ULA on the Speedport
and set its own upstream DNS (Internet → Internetverbindung → Zugangsdaten → DNS-Server) to Pi-hole: DNSv4 the LAN
address, DNSv6 the host's stable ULA. Since then queries via `fe80::1` reach Pi-hole with the Speedport as the
client. Pi-hole's `DHCP_IPv6` stays off. The Speedport's DNS rebind protection later needed exceptions for the LAN
domains (see the dumont change).

## Gravity and blocklists (2026-10-03)

- The schema-20 `gravity.db` from the failed v6 attempt had frozen the blocklists since 2026-05-03: every v5 run
  failed at `INSERT … SELECT * FROM OLD.adlist` (12 vs. 10 columns). Rebuilt as schema 15 from the image's template
  and `gravity_copy.sql` with an explicit column list. The allowlist entries were kept and the dead lists dropped.
- Lists reduced to StevenBlack (hosts) and HaGeZi Multi PRO from `raw.githubusercontent.com`. The jsdelivr URL
  in HaGeZi's README returned 403. FTL 5.25 matches the ABP `||domain^` entries including subdomains.
- In v5, deleting an adlist via `pihole -a adlist del` fails on a foreign key while gravity rows reference it.
  Delete gravity → adlist_by_group → adlist in one transaction, then `pihole -g`.

## Monitoring (designed, not built)

A user timer on reason was built and dropped, because reason is mostly off. The checks and open questions are now
the monitoring item under "Planned" in [`docs/hosts.md`](../../hosts.md).
