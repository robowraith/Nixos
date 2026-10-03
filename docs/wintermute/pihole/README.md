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
