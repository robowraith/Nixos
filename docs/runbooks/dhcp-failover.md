# Fail LAN DHCP over to wintermute (and back)

wintermute's Pi-hole is a **cold standby** for dumont's DHCP (`openspec/changes/add-dumont-pihole-host`, design D11):
same range and router, DHCP off. It is turned on by hand only while dumont is down, and off again before dumont
serves DHCP. Every step that changes wintermute or dumont is done by the user.

**Rule: never two DHCP servers at once.** Both run authoritative, so each would reject the other's leases and clients
would bounce between them. A short gap with no DHCP server is harmless; an overlap is not.

kubectl context: `home_cluster` on deepthought, `wintermute` on reason (examples use `home_cluster`). wintermute's
login shell is fish.

## Normal state

| | dumont (`.2`) | wintermute (`.3`) |
|---|---|---|
| DHCP | on, `.12`–`.254`, 24 h, router `.1`, hands out DNS `.2` | **off**, same range and router, lease **1 h** |
| Reservations | `secrets/dumont.yaml` inventory | v5: its own `04-pihole-static-dhcp.conf` (pre-cutover copy) |

Check (verified 2026-10-29):
```
ssh yori@192.168.1.2 "ss -ulnH 'sport = :67'"     # one line: 0.0.0.0:67
ssh server "ss -ulnH 'sport = :67'"               # nothing
ssh server "grep -E '^DHCP_' /etc/pihole/config/setupVars.conf"
# DHCP_ACTIVE=false, DHCP_START=192.168.1.12, DHCP_END=192.168.1.254, DHCP_ROUTER=192.168.1.1, DHCP_LEASETIME=1
```

## When to fail over

dumont's leases last 24 h and clients first try to renew after 12 h, so devices that already have a lease keep their
address for at least 12 h after dumont dies. New devices, guests and phones rejoining the Wi-Fi are hit first.

1. Try to get dumont back first: power-cycle it. It always boots the last generation that passed the deploy checks
   (`dumont-deploy.md`, Last resort).
2. Fail over only if dumont stays down and it will take longer than a few hours to fix, or a device needs to join
   now.

DHCP failover does **not** restore DNS for clients holding a dumont lease: they keep DNS `.2` until they get a new
lease. Clients that ask the Speedport (IPv6 RDNSS `fe80::1`) should still resolve through its secondary, wintermute
(not tested). To move a device over right away, reconnect it (Wi-Fi off/on, `nmcli connection down/up <conn>`):
wintermute, being authoritative, answers its request and hands it a lease with DNS `.3` (usually the same address).

## Fail over: DHCP on at wintermute

**v5 (until task 8.7):**
1. Make sure dumont is really not serving DHCP: `ssh yori@192.168.1.2 "ss -ulnH 'sport = :67'"` fails or prints
   nothing. If dumont is up but broken, stop its DHCP first (`dhcp.active = false` + deploy), or power it off.
2. Turn DHCP on, with a 1 h lease:
   ```
   kubectl --context home_cluster -n pihole exec deploy/pihole-deployment -- \
     pihole -a enabledhcp 192.168.1.12 192.168.1.254 192.168.1.1 1 meine2cent.home
   ```
   (Or the web UI from reason, the only client allowed on wintermute's `/admin`.)
3. The command blanks `DHCP_IPv6` and `DHCP_rapid_commit` (seen 2026-10-25). Make sure no router advertisements
   are configured, since only the Speedport may send RAs:
   ```
   kubectl --context home_cluster -n pihole exec deploy/pihole-deployment -- \
     grep -nE 'constructor|ra-|enable-ra' /etc/dnsmasq.d/02-pihole-dhcp.conf    # must print nothing
   ```
   Set both keys back to `false` (UI from reason → Settings → DHCP → Save with IPv6 unticked) once things are calm.

**v6 (after task 8.7):** set `dhcp.active = true` on wintermute: in its Nix config and rebuild if wintermute runs
NixOS, or `pihole-FTL --config dhcp.active true` in the container. Update this section when 8.7 is done.

**Check:**
- `ssh server "ss -ulnH 'sport = :67'"` prints a listener
- a reconnected device gets an address in `.12`–`.254`, gateway `.1`, and its lease is from wintermute:
  ```
  nmcli -f DHCP4 device show wlo1 | grep -E 'dhcp_server_identifier|dhcp_lease_time'
  # dhcp_server_identifier = 192.168.1.3, dhcp_lease_time = 3600
  ```
- `rdisc6 <iface>` (`, rdisc6`) still only answers from `fe80::1`

Reservations come from wintermute's own pre-cutover list. A device reserved on dumont only after the cutover gets a
dynamic address while failed over.

## Fail back: wintermute off, then dumont

Turn wintermute off **before** dumont serves DHCP again: before powering dumont on, before a deploy that brings it
back, or right away if dumont comes back by itself (its DHCP starts at boot).

1. wintermute DHCP off:
   - v5: `kubectl --context home_cluster -n pihole exec deploy/pihole-deployment -- pihole -a disabledhcp`
   - v6: `dhcp.active = false` (Nix config or `pihole-FTL --config dhcp.active false`)
2. Check: `ssh server "ss -ulnH 'sport = :67'"` prints nothing.
3. Bring dumont back (power on, or `nix run .#deploy-dumont`). Check: `ssh yori@192.168.1.2 "ss -ulnH 'sport = :67'"`
   prints one listener.
4. Clients holding a wintermute lease fail to renew with wintermute, then rebind by broadcast at 87.5% of the 1 h
   lease. dumont answers them, since it is authoritative, so within an hour they are back on dumont with DNS `.2`.
   Reconnecting a device does it at once. dnsmasq pings an address before offering it, which covers dynamic
   addresses wintermute handed out meanwhile.
5. Check on a reconnected device: `dhcp_server_identifier = 192.168.1.2`, `dhcp_lease_time = 86400`.
6. Leave wintermute's lease time at 1 h; it only matters during the next failover.
