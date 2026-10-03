# Pi-hole on wintermute (k3s)

Source of truth for the Pi-hole objects in wintermute's k3s cluster. Before this directory existed they
lived only in the cluster and drifted; see `pihole_wintermute_handoff.md` in the repo root for the history.

kubectl access from reason: context `wintermute` (`~/.kube/wintermute.config`, merged by `kmerge`).

## Files

| File | Contents |
|---|---|
| `pihole.yaml` | Pi-hole Deployment, its Services, the web Ingress/IngressRoute and Middlewares |
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
there and is the user's job.

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

- DNS v4: `dig @192.168.1.3 example.com`, plus a `*.meine2cent.home` name
- DNS v6: `dig @<eno2 EUI-64 address, stable EUI-64 suffix> example.com`
- No RA from Pi-hole: `rdisc6 enp7s0` on reason shows only the Speedport (`fe80::1`)
- DHCP, actively: reconnect one device, then check `pihole.log` for its DHCPACK, and that the device got
  `192.168.1.3` (not the secondary `.4` on `eno2`) as DNS server and gateway `.1`
- Web: `http://pihole.meine2cent.home/admin` (502 means lighttpd is not on :8080)
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
