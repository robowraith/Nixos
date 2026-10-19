# Deploy to dumont

Run on a desktop (reason or deepthought), from the flake root. Everything addresses dumont by IP
(`yori@192.168.1.2`), so it works while LAN DNS is down.

## Normal deploy
```
nix run .#deploy-dumont
```
1. Builds dumont's system **here** (it is a build input of the app), then `nix copy`s it with
   `--substitute-on-destination`, so dumont fetches what it can from cache.nixos.org.
2. Asks once for yori's sudo password.
3. Activates with `switch-to-configuration test` (in a transient unit, so a dropped SSH session does not abort it).
   The boot default does **not** change yet.
4. Health checks from this machine, retried for ~30 s:

   | Check | Meaning when it fails |
   |---|---|
   | `dns` | `dig @192.168.1.2 example.com` returns no address: FTL down or upstreams unreachable |
   | `blocking` | `doubleclick.net` is not `0.0.0.0`: gravity not loaded (see the SIGRTMIN note in `pihole.nix`) |
   | `ssh` | dumont lost its network or sshd |
   | `pihole-ftl` | the unit is not active, e.g. a bad inventory line |
| `pihole-ftl-setup` | adding lists or running gravity failed (list URL down, API login) |

5. All pass: the generation becomes the boot default (`nix-env --set` + `switch-to-configuration boot`).
   Any fail: the previous generation is re-activated with `test`, the failing checks are printed, exit 1.

The host key is pinned to `system/hosts/dumont/ssh_host_ed25519_key.pub`; a mismatch aborts.

`--help` prints the steps and the exact store path that would be deployed.

## Manual rollback
If the automatic revert fails or a bad generation was made default:
```
ssh yori@192.168.1.2
sudo nix-env -p /nix/var/nix/profiles/system --list-generations
sudo nix-env -p /nix/var/nix/profiles/system --rollback
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

## Last resort
- **No SSH:** power-cycle dumont. Since the boot default only moves after the checks pass, it boots the last good
  generation.
- **Still broken:** monitor + keyboard, pick an older generation in the systemd-boot menu.
- **Unbootable:** reinstall (`dumont-install.md`); all state except query history is in the repo and
  `secrets/dumont.yaml`.

## One-time bootstrap (first deploy after install)
Copying locally built paths needs yori to be a trusted nix user, which the server hostgroup's
`remote-deploy.nix` sets. A dumont installed before that change does not have it yet, so its first deploy builds on
dumont instead:
```
nixos-rebuild switch --flake .#dumont --target-host yori@192.168.1.2 --build-host yori@192.168.1.2 \
  --sudo --ask-sudo-password --use-substitutes
```
Verified 2026-10-19: this works (dumont builds the few non-cached paths itself). `--ask-sudo-password` feeds
sudo via `--stdin`, so a mistyped password fails at the final `nix-env --set` step without activating anything; just
rerun, the build is already on dumont. Fallback if the copy ever fails: reinstall (`dumont-install.md`).

Afterwards use `nix run .#deploy-dumont`.
