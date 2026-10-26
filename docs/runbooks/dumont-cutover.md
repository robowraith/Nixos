# Cut over LAN DHCP + DNS from wintermute to dumont

Phase 3 of `openspec/changes/add-dumont-pihole-host` (design.md, Migration Plan). Every step that changes wintermute,
dumont or the Speedport is done by the user. `<ula-prefix>::2` is dumont's ULA address (`ip -6 addr` on dumont); it is
not written into this public repo.

## Starting point

| | wintermute (`.3`) | dumont (`.2`) |
|---|---|---|
| DNS | answers the LAN | answers, used only by the trial-run desktops |
| DHCP | on, `.12`–`.254`, 24 h, router `.1`, hands out `.3` as DNS | configured identically, `dhcp.active = false` |
| Reservations, local names | `04-pihole-static-dhcp.conf`, `custom.list`, CNAMEs | same, from `secrets/dumont.yaml` |

Why the order matters: clients renew their lease unicast against the server that gave it, and keep the DNS server
from that lease until they renew. wintermute's DNS therefore keeps running until every 24 h lease has been replaced.

## 0. Preconditions
- Trial run (task 7.4) finished without open issues.
- dumont healthy: `nix run .#deploy-dumont` of the current main passes.
- `.2` is outside the dynamic range (`.12`–`.254`) and not reserved. Check that it is still true:
  ```
  ssh server "sh -c 'grep -E \"^DHCP_(START|END|LEASETIME)\" /etc/pihole/config/setupVars.conf; grep -c \",192.168.1.2,\" /etc/pihole/dnsmasq.d/04-pihole-static-dhcp.conf'"
  ```
  Expect `DHCP_START=192.168.1.12`, `DHCP_END=192.168.1.254`, `DHCP_LEASETIME=24` and a count of `0`.

## 1. Shorten wintermute's lease time (≥ 24 h before step 2)
1. wintermute's Pi-hole UI → Settings → DHCP → lease time `1` (hour) → Save. This restarts FTL; DNS is gone for a
   few seconds.
2. Wait **at least 24 h** (one old lease period) so every client holds a 1 h lease.
3. Check: `ssh server "sh -c 'grep DHCP_LEASETIME /etc/pihole/config/setupVars.conf'"` → `1`.

## 2. Handover (one sitting, ~15 min)
1. **wintermute: DHCP off.** UI → Settings → DHCP → uncheck "DHCP server enabled" → Save. DNS keeps running.
2. **dumont: DHCP on.** In `system/hosts/dumont/modules/pihole.nix` set `dhcp.active = true;` (the comment there
   says this is the handover), commit, then from the flake root:
   ```
   nix run .#deploy-dumont
   ```
   The health checks cover DNS, not DHCP; step 4 checks DHCP.
3. **Speedport: DNS to dumont.** In its DNS settings (Heimnetz): DNSv4 `192.168.1.2`, DNSv6 `<ula-prefix>::2`. Its DHCP stays
   off. Secondary DNSv4/v6: wintermute's Pi-hole (`192.168.1.3` and its stable EUI-64 ULA, not the privacy
   address), not Quad9.
4. **Checks** (on reason; adjust the interface name elsewhere):
   - reserved device gets its address, DNS and gateway:
     ```
     nmcli device reapply enp7s0      # or: nmcli connection down/up <conn>
     ip -4 addr show enp7s0           # 192.168.1.111
     ip route | grep default          # via 192.168.1.1
     nmcli device show enp7s0 | grep IP4.DNS   # 192.168.1.2 (unless the trial-run override is still set)
     ```
   - only the Speedport sends router advertisements: `, rdisc6 enp7s0` → one answer, from `fe80::1`
   - DNS via the Speedport reaches dumont: `dig @fe80::1%enp7s0 example.com`, then find the query in dumont's
     query log (web UI)
   - dumont's query log shows real client IPs, not only the Speedport
   - a phone or TV reconnected to the LAN gets an address in `.12`–`.254` and resolves names
5. Remove the trial-run DNS override from the desktops' NetworkManager connections; they now get `.2` via DHCP.

## 3. Keep wintermute's Pi-hole as secondary DNS (changed 2026-10-26)
wintermute's v5 Pi-hole stays running with DHCP off: it is the Speedport's secondary DNS (2.3). Do **not** scale it
to 0 while the Speedport points at it.
1. Check LAN DNS from a device that is neither a desktop nor dumont (phone): browsing works, a local name such as
   `wintermute.meine2cent.home` resolves.
2. Remove the trial-run override on deepthought (step 2.5).
3. Reinstall it as a v6 DNS-only Pi-hole later (task 8.7); only then retire the v5 setup.

Deleting the v5 k3s objects, the `.4` address, the `pi.hole` PTR and `99-root-ksk-2024.conf` is phase 4 (task 9.1),
after the v6 reinstall and ~2 weeks stable.

## Rollback (any time before phase 4)
In this order, so the LAN never has two DHCP servers and never none for long:
1. dumont: `dhcp.active = false`, commit, `nix run .#deploy-dumont`.
2. Speedport: DNSv4 `192.168.1.3`, DNSv6 wintermute's ULA address.
3. wintermute: if scaled to 0, `kubectl --context home_cluster -n pihole scale deploy/pihole-deployment --replicas=1`
   and wait until the pod is ready. Then DHCP on: UI from reason, or
   `pihole -a enabledhcp 192.168.1.12 192.168.1.254 192.168.1.1 24 meine2cent.home` in the pod.
4. wintermute: lease time back to 24 h → Save.
5. Clients that got a lease from dumont keep `.2` as DNS until they renew (≤ 1 h if dumont handed out 1 h leases,
   else up to 24 h). dumont's DNS stays up during that time, so nothing breaks.
