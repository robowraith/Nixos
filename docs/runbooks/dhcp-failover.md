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
| DHCP | on, `.12`–`.254`, 72 h, router `.1`, hands out DNS `.2` + `.3` | **off**, same range and router, lease **1 h** |
| Reservations | `secrets/dumont.yaml` inventory | the same inventory (Secret `pihole-inventory`) |

wintermute runs Pi-hole v6 since 2026-11-24 (task 8.7); its settings are rendered from dumont's config
(`docs/wintermute/pihole/README.md` → Pi-hole v6).

Check (verified 2026-11-24):
```
ssh yori@192.168.1.2 "ss -ulnH 'sport = :67'"     # one line: 0.0.0.0:67
ssh server "ss -ulnH 'sport = :67'"               # nothing
for k in dhcp.active dhcp.leaseTime dhcp.start dhcp.end dhcp.router; do
  kubectl --context home_cluster -n pihole exec deploy/pihole-deployment -- pihole-FTL --config $k
done
# false, 1h, 192.168.1.12, 192.168.1.254, 192.168.1.1
```

## When to fail over

dumont's leases last 72 h and clients first try to renew after 36 h, so devices that already have a lease keep their
address for at least 36 h after dumont dies. New devices, guests and phones rejoining the Wi-Fi are hit first.

1. Try to get dumont back first: power-cycle it. It always boots the last generation that passed the deploy checks
   (`dumont-deploy.md`, Last resort).
2. Fail over only if dumont stays down and it will take longer than a few hours to fix, or a device needs to join
   now.

DNS keeps working without a failover: dumont hands out wintermute (`.3`) as second DNS server, and the Speedport's
secondary is wintermute too. Some clients wait for a timeout on `.2` first, so lookups can be slow. To move a device
over to a wintermute lease right away, reconnect it (Wi-Fi off/on, `nmcli connection down/up <conn>`): wintermute,
being authoritative, answers its request (usually with the same address).

## Fail over: DHCP on at wintermute

1. Make sure dumont is really not serving DHCP: `ssh yori@192.168.1.2 "ss -ulnH 'sport = :67'"` fails or prints
   nothing. If dumont is up but broken, stop its DHCP first (`dhcp.active = false` + deploy), or power it off.
2. Turn DHCP on. The settings are `FTLCONF_*` env vars (`docs/wintermute/pihole/README.md` → Pi-hole v6), so
   `pihole-FTL --config` and the UI cannot change them. Set the env var instead; this restarts the pod, a few
   seconds without DNS on `.3`:
   ```
   kubectl --context home_cluster -n pihole set env deploy/pihole-deployment FTLCONF_dhcp_active=true
   ```
   No RA check needed: `dhcp.ipv6 = false` comes from the manifest. Reservations are dumont's inventory (Secret
   `pihole-inventory`), so reserved devices keep their addresses.

**Check:**
- `ssh server "ss -ulnH 'sport = :67'"` prints a listener
- a reconnected device gets an address in `.12`–`.254`, gateway `.1`, and its lease is from wintermute:
  ```
  nmcli -f DHCP4 device show wlo1 | grep -E 'dhcp_server_identifier|dhcp_lease_time'
  # dhcp_server_identifier = 192.168.1.3, dhcp_lease_time = 3600
  ```
- `rdisc6 <iface>` (`, rdisc6`) still only answers from `fe80::1`

Bare names (`reason` without the domain) only resolve for devices that have a lease from wintermute; the
`.internal` names of reserved devices resolve throughout.

## Fail back: wintermute off, then dumont

Turn wintermute off **before** dumont serves DHCP again: before powering dumont on, before a deploy that brings it
back, or right away if dumont comes back by itself (its DHCP starts at boot).

1. wintermute DHCP off:
   `kubectl --context home_cluster -n pihole set env deploy/pihole-deployment FTLCONF_dhcp_active=false`,
   or re-apply the manifest (`nix build .#wintermute-pihole && kubectl apply -f result`)
2. Check: `ssh server "ss -ulnH 'sport = :67'"` prints nothing.
3. Bring dumont back (power on, or `nix run .#deploy-dumont`). Check: `ssh yori@192.168.1.2 "ss -ulnH 'sport = :67'"`
   prints one listener.
4. Clients holding a wintermute lease fail to renew with wintermute, then rebind by broadcast at 87.5% of the 1 h
   lease. dumont answers them, since it is authoritative, so within an hour they are back on dumont with DNS `.2`.
   Reconnecting a device does it at once. dnsmasq pings an address before offering it, which covers dynamic
   addresses wintermute handed out meanwhile.
5. Check on a reconnected device: `dhcp_server_identifier = 192.168.1.2`, `dhcp_lease_time = 259200`.
6. Leave wintermute's lease time at 1 h; it only matters during the next failover.
