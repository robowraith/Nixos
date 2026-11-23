# Pi-hole on wintermute (k3s)

Source of truth for the Pi-hole objects in wintermute's k3s cluster. Before this directory existed they
lived only in the cluster and drifted; see `pihole_wintermute_handoff.md` in the repo root for the history.

kubectl access from reason: context `wintermute` (`~/.kube/wintermute.config`, merged by `kmerge`).

## Files

| File | Contents |
|---|---|
| `pihole.yaml` | **v5** (live until task 8.7): Pi-hole Deployment, its Services, the web Ingress/IngressRoute and Middlewares. After 8.7 it is the rollback |
| `v6.nix` | **v6**: the replacement, rendered from dumont's Pi-hole config (`nix build .#wintermute-pihole`), see Pi-hole v6 below |
| `shims.yaml` | dhcp-relay, ipv6-proxy, ip-watcher (+ RBAC, ConfigMap): workarounds for FTL running in the pod network |
| `traefik-dns-routes.yaml` | Traefik IngressRouteUDP/TCP that carried LAN DNS (and an unused DHCP route) into the pod |
| `traefik-helmchartconfig.yaml` | Copy of the Traefik HelmChartConfig exposing :53. **Not applied from here**: k3s owns it via the addon file `/var/lib/rancher/k3s/server/manifests/traefik-config.yaml` and re-applies that file on every start |

## Admin password

The Deployment reads `WEBPASSWORD` from the Secret `pihole-web-password`. The value lives SOPS-encrypted in
`secrets/wintermute-pihole.yaml` (a ready-made Secret manifest):

```bash
sops -d secrets/wintermute-pihole.yaml | kubectl --context wintermute apply -f -
```

## Applying

```bash
kubectl --context wintermute apply -f docs/wintermute/pihole/pihole.yaml
```

Anything that has to happen on wintermute itself (addon files, `/etc/pihole/config/setupVars.conf`) needs sudo
there and is the user's job. On wintermute there is no `wintermute` context: use `sudo k3s kubectl`.

## Pi-hole v6 (tasks 8.7 + 8.8, prepared 2026-11-23, not applied)

Replaces the v5 pod with `pihole/pihole:2026.11.0` (FTL 6.9, Core 6.6) as wintermute's DNS and the cold DHCP standby
for dumont (design D11 in `openspec/changes/add-dumont-pihole-host`). `v6.nix` builds the manifest from
`nixosConfigurations.dumont.config.services.pihole-ftl`, so wintermute gets dumont's upstreams, DNSSEC, domain,
DHCP range/router, `dnsmasq_lines` and lists by construction. Intended differences only:

| | dumont | wintermute v6 |
|---|---|---|
| `dhcp.active` | `true` | `false` (cold standby) |
| `dhcp.leaseTime` | `72h` | `1h` (D11: clients come back to dumont within an hour after a failback) |
| inventory | `/run/secrets/pihole_inventory` | Secret `pihole-inventory`, made from the same `secrets/dumont.yaml` key |
| web | `:80`, `dumont.meine2cent.internal` | `:8080` behind Traefik, `pihole.meine2cent.internal` (+ old `.home` host) |
| state | `/var/lib/pihole` | hostPath `/etc/pihole-v6` (new; v5's `/etc/pihole/config` stays untouched for the rollback) |

All settings are `FTLCONF_*` env vars: FTL re-applies them on every start and the UI/`--config` cannot change
them. Not carried over from v5: `/etc/dnsmasq.d` (v5 DHCP files, the KSK-2024 hack; v6 ships the anchor), the PHP
CVE ConfigMap (no PHP in v6; `/admin` is open to the LAN again, as on dumont), `INTERFACE` (`dns.listeningMode =
LOCAL` instead). DHCP hands out `.2, .3`, the same as dumont; in a failover clients try `.2` first and fall back.

kubectl context: `wintermute` on reason, `home_cluster` on deepthought (examples: `wintermute`). Every step that
changes the cluster or wintermute is the user's.

### Preconditions

- dumont is healthy and serves DNS + DHCP: wintermute's DNS (`.3`) is down for a few seconds during the switch,
  which only affects clients falling back to it.
- wintermute's DHCP is off: `ssh server "ss -ulnH 'sport = :67'"` prints nothing.
- Clean tree at origin/main, so the manifest matches what dumont runs.

### Steps

1. Build and review the manifest (a Kubernetes `List` in JSON):
   ```bash
   nix build .#wintermute-pihole
   jq -r '.items[] | select(.kind=="Deployment") | .spec.template.spec.containers[0].env[] | "\(.name)=\(.value // "<secret>")"' result
   ```
2. Pre-pull the image so the switch takes seconds: `ssh server sudo k3s crictl pull docker.io/pihole/pihole:2026.11.0`
3. Inventory Secret from dumont's sops file (contains MACs: never write it to the repo):
   ```bash
   sudo SOPS_AGE_KEY_FILE=/var/lib/sops/age/keys.txt sops -d --extract '["pihole_inventory"]' secrets/dumont.yaml \
     | kubectl --context wintermute -n pihole create secret generic pihole-inventory \
         --from-file=inventory.conf=/dev/stdin --dry-run=client -o yaml \
     | kubectl --context wintermute apply -f -
   ```
4. Switch. Delete first: an `apply` over the v5 Deployment would merge in its old env and volumes.
   ```bash
   kubectl --context wintermute -n pihole delete deployment pihole-deployment
   kubectl --context wintermute apply -f result
   kubectl --context wintermute -n pihole rollout status deploy/pihole-deployment
   ```
5. Seed the gravity lists (adlists are in `gravity.db`, not the config):
   ```bash
   kubectl --context wintermute -n pihole exec deploy/pihole-deployment -- sh /etc/pihole-lists/sync-lists.sh
   ```
6. After the checks pass: `kubectl --context wintermute -n pihole delete configmap pihole-php-cve-2026`

### Checks

```bash
kubectl --context wintermute -n pihole exec deploy/pihole-deployment -- pihole -v          # FTL v6.9
kubectl --context wintermute -n pihole exec deploy/pihole-deployment -- pihole-FTL --config dhcp.active     # false
kubectl --context wintermute -n pihole exec deploy/pihole-deployment -- pihole-FTL --config dhcp.leaseTime  # 1h
ssh server "ss -ulnH 'sport = :67'"                       # nothing: standby, never a second DHCP server
dig @192.168.1.3 example.com                              # NOERROR
dig +short @192.168.1.3 doubleclick.net                   # 0.0.0.0
dig +short @192.168.1.3 dumont.meine2cent.internal        # 192.168.1.2 (inventory loaded)
dig @192.168.1.3 dnssec-failed.org                        # SERVFAIL (validation on, no KSK file needed)
ssh server "ip -6 addr show eno2 scope global"            # then: dig @<ULA> example.com
rdisc6 enp7s0                                             # only fe80::1 (the Speedport)
```

- The lists loaded, including the `file://` allowlist from the ConfigMap (its files are `..data` symlinks, which
  newer FTL/Core releases handle more strictly). Every row needs `status` 1 or 2 and a non-zero `number`:
  ```bash
  kubectl --context wintermute -n pihole exec deploy/pihole-deployment -- \
    pihole-FTL sqlite3 /etc/pihole/gravity.db "select address, enabled, type, status, number from adlist"
  ```
  If the allowlist row fails, copy the file to a real path in the pod (or inline the domains) instead.
- Same answers as dumont for a few blocked, allowed (`pihole-allowlist.txt`) and local names: `dig +short @192.168.1.2`
  vs `@192.168.1.3`. Include a host-record name (`dumont.meine2cent.internal`) and reserved DHCP clients
  (`reason.meine2cent.internal`, `deepthought.meine2cent.internal`). If the reserved names stay empty on `.3`, the
  inventory only gives them a DNS name through an active lease (`dhcp-host`), which the standby has none of while
  DHCP is off: a known standby limitation. Record it in task 8.7, or add `host-record` lines to the inventory.
- Web: `http://pihole.meine2cent.internal/admin/` loads and the login works (password from
  `secrets/wintermute-pihole.yaml`). The query log shows real client IPs.

### Rollback

v5's state is untouched (`/etc/pihole/config`, `/etc/pihole/dnsmasq.d`), so:

```bash
kubectl --context wintermute -n pihole delete deployment pihole-deployment
kubectl --context wintermute apply -f docs/wintermute/pihole/pihole.yaml
```

The v5 `pihole.yaml` has only the `.internal` Ingress host, so this drops the old `.home` host: acceptable.

### Later changes

- Settings or lists changed on dumont: `nix build .#wintermute-pihole && kubectl --context wintermute apply -f result`
  (a changed env restarts the pod), then re-run `sync-lists.sh` if the lists changed. Like dumont, it only adds lists.
- Inventory changed in `secrets/dumont.yaml`: re-run step 3, then
  `kubectl --context wintermute -n pihole rollout restart deploy/pihole-deployment` (FTL reads `conf-file` at start).
- New image: bump `image` in `v6.nix`.

## PHP RCE stopgap (CVE-2026-109618/-109619, 2026-10-22)

The v5 web UI runs PHP 7.4.33 (Debian 11) as persistent php-cgi workers. Neither PHP nor Debian will fix that
version; only Pi-hole v6 (no PHP) does. Until then the ConfigMap `pihole-php-cve-2026` in `pihole.yaml`:

- makes lighttpd refuse `/admin` to everyone except reason (`192.168.1.111`) before php-cgi sees the request.
  Traefik SNATs, so `pihole.meine2cent.internal` now answers 403: use `http://192.168.1.3:8080/admin/` from reason.
  deepthought has no DHCP reservation and is locked out too.
- sets `session.upload_progress.enabled = 0` (blocks the confirmed CVE-2026-109619 path, not all variants).

Applied live on 2026-10-22 without restarting FTL: ConfigMap applied on its own, both files copied into the
running container, then `/command/s6-svc -r /run/service/lighttpd`. The Deployment's mounts take over on the
next pod restart. Checks: from reason `curl -so /dev/null -w '%{http_code}' http://192.168.1.3:8080/admin/` → 302;
inside the pod the same against `127.0.0.1` → 403. Drop the ConfigMap and mounts when moving to v6.

## Root KSK-2024 trust anchor (2026-10)

On 2026-10-11 the root zone switched its signing key from KSK-2017 (id 20326) to KSK-2024 (id 38696). The image
(`pihole/pihole:2024.07.0`, Pi-hole v5) only ships the KSK-2017 anchor, so with DNSSEC enabled every lookup
returned SERVFAIL with `EDE: 6 (DNSSEC Bogus)`. Restarting the pod does not help. Diagnosis: the same query
with `dig +cd` (checking disabled) answers fine.

Fix, on wintermute (`/etc/pihole/dnsmasq.d` is the hostPath behind the pod's `/etc/dnsmasq.d`; Pi-hole v5 does
not touch `99-*` files):

```bash
echo 'trust-anchor=.,38696,8,2,683D2D0ACB8C9B712A1948B27F741219298D0A450D612C483AF444A4C0FB2B16' \
  | sudo tee /etc/pihole/dnsmasq.d/99-root-ksk-2024.conf
sudo k3s kubectl -n pihole exec deploy/pihole-deployment -- pihole restartdns
```

Checks: `dig @192.168.1.3 example.com` → NOERROR, `dig @192.168.1.3 dnssec-failed.org` → SERVFAIL (validation
still on).

**TODO:** upgrade to Pi-hole v6, which ships both anchors. The upgrade is a migration (config moves to
`pihole.toml`, env vars renamed), not a tag bump. Drop `99-root-ksk-2024.conf` afterwards.

## hostNetwork cutover (2026-10)

**Done 2026-10-03, 16:30–16:32.** DNS was down ~50 s. All checks passed: DNS v4 and v6 (v6 had been dead
since the last prefix rotation), blocking, web UI on :8080 via Traefik, DHCP on `eno2` (SV08 re-lease), no RA,
real client IPs in the query log.

FTL used to run in the pod network, reached via Traefik (IPv4 DNS), `pihole-ipv6-proxy` (IPv6 DNS) and
`pihole-dhcp-relay` (DHCP), with `pihole-ip-watcher` patching the shims whenever the pod IP or the IPv6 prefix
changed. With `hostNetwork: true` FTL binds wintermute's `eno2` directly and all of that goes away. Lighttpd
moves to :8080 because Traefik's ServiceLB owns :80 on the host.

Prerequisites:

1. Secret exists with the right key (never print the value):
   `kubectl -n pihole get secret pihole-web-password -o jsonpath='{.data}' | yq 'keys'` → `[WEBPASSWORD]`.
   A missing Secret leaves the new pod in `CreateContainerConfigError`, i.e. the outage does not end.
2. IPv6 DHCP/RA is off in the web UI (Settings → DHCP → untick IPv6 support, save). Verify:
   `kubectl -n pihole exec deploy/pihole-deployment -- grep -nE 'constructor|ra-|enable-ra' /etc/dnsmasq.d/02-pihole-dhcp.conf`
   must print nothing. The generated `dhcp-range=::,constructor:<if>,ra-names,ra-stateless,64` line is what
   makes dnsmasq send Router Advertisements; `#enable-ra` being commented out does not stop it. It was only
   inert because the pod's `eth0` had no global prefix. `eno2` has one. The start script does not regenerate
   this file (it only does when `DHCP_ACTIVE` is set as an env var), so the UI is the lever.

Order (DNS + DHCP are down from step 2 until step 4 finishes):

1. On wintermute: `sudo mv /var/lib/rancher/k3s/server/manifests/traefik-config.yaml ~server/`
2. `kubectl -n kube-system delete helmchartconfig traefik` (and `addon traefik-config` if it is still there).
   Wait until `kubectl -n kube-system get svc traefik` no longer lists port 53 and the svclb-traefik pod has
   been recreated. Timeout 5 minutes, then roll back. Symptom if skipped: the new Pi-hole pod sits `Pending`
   ("didn't have free ports"), because hostNetwork defaults each hostPort to its containerPort.
3. `kubectl delete -f shims.yaml -f traefik-dns-routes.yaml`, plus the Services `pihole-dns-tcp`, `pihole-dns-udp`,
   `pihole-dns-headless`, `pihole-dhcp4`
4. `kubectl replace` the Deployment from `pihole.yaml` (replace, not apply: apply would keep the old
   `rollingUpdate` block, which is invalid with `Recreate`), then `kubectl apply` the rest of the file

Checks:

- DNS v4: `dig @192.168.1.3 example.com`, plus a `*.meine2cent.internal` name
- DNS v6: `dig @<eno2 EUI-64 address, stable EUI-64 suffix> example.com`
- No RA from Pi-hole: `rdisc6 enp7s0` on reason shows only the Speedport (`fe80::1`)
- DHCP, actively: reconnect one device, then check `pihole.log` for its DHCPACK, and that the device got
  `192.168.1.3` (not the secondary `.4` on `eno2`) as DNS server and gateway `.1`
- Web: `http://pihole.meine2cent.internal/admin` (502 means lighttpd is not on :8080)
- Query log shows real client IPs instead of Traefik's

Rollback, in this order (otherwise the relay and the proxy collide with the hostNetwork pod on :67/:53):

1. Put `traefik-config.yaml` back into the manifests directory (k3s re-creates the HelmChartConfig)
2. `git checkout d313edb -- docs/wintermute/pihole`. This repo is public, so wintermute's public IPv6 address is
   replaced by `<wintermute-public-ipv6>` in the snapshot: drop the `ServerIPv6` env var from the Deployment and put
   the current `eno2` address into the ipv6-proxy Corefile's `bind` line before applying.
3. `kubectl replace` the Deployment from `pihole.yaml` and wait until the hostNetwork pod has terminated
4. `kubectl apply -f pihole.yaml -f traefik-dns-routes.yaml -f shims.yaml` (not `traefik-helmchartconfig.yaml`,
   see above). The Services come back with new ClusterIPs while the ipv6-proxy ConfigMap still names the old
   ones, so patch the Corefile's `forward` line; IPv6 DNS was already broken before the cutover anyway.
