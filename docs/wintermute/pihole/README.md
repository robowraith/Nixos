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

FTL used to run in the pod network, reached via Traefik (IPv4 DNS), `pihole-ipv6-proxy` (IPv6 DNS) and
`pihole-dhcp-relay` (DHCP), with `pihole-ip-watcher` patching the shims whenever the pod IP or the IPv6 prefix
changed. With `hostNetwork: true` FTL binds wintermute's `eno2` directly and all of that goes away. Lighttpd
moves to :8080 because Traefik's ServiceLB owns :80 on the host.

Prerequisites:

1. Secret exists: `kubectl --context wintermute -n pihole get secret pihole-web-password`
2. IPv6 DHCP/RA is off in the web UI (Settings → DHCP), so `DHCP_IPv6=false` in `setupVars.conf`. Otherwise FTL
   would start sending Router Advertisements as soon as it sees `eno2`'s real prefix. RA is a separate step.

Order (DNS + DHCP are down from step 2 until step 5):

1. On wintermute: `sudo mv /var/lib/rancher/k3s/server/manifests/traefik-config.yaml ~server/`
2. `kubectl -n kube-system delete helmchartconfig traefik` (and `addon traefik-config` if it is still there);
   wait for the svclb-traefik pod to come back without :53
3. `kubectl delete -f shims.yaml -f traefik-dns-routes.yaml`, plus the Services `pihole-dns-tcp`, `pihole-dns-udp`,
   `pihole-dns-headless`, `pihole-dhcp4`
4. `kubectl replace` the Deployment from `pihole.yaml` (replace, not apply: apply would keep the old
   `rollingUpdate` block, which is invalid with `Recreate`), then `kubectl apply` the rest of the file
5. Check: `dig @192.168.1.3`, `dig @<eno2 EUI-64 IPv6>`, FTL on `0.0.0.0:67`, a DHCP lease in
   `pihole.log`, `http://pihole.meine2cent.home/admin`

Rollback: put `traefik-config.yaml` back, `git checkout f55c1ab -- docs/wintermute/pihole`, `kubectl replace`
the Deployment and `kubectl apply -f` all four files.
