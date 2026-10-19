# Handoff — add-dumont-pihole-host

## Session 2026-10-19 (deepthought) — READ FIRST
**Progress 21/30 (7.3 + 8.1 done). dumont runs at 192.168.1.2, DNS + blocking live, DHCP off (range .12-.254 ready).**
- Deploy: `nix run .#deploy-dumont` from the flake root; asks yori's sudo password first. Verified: healthy deploy
  switches; a broken one (unreachable upstream) reverts and exits 1.
- Fixed along the way (all pushed): `neededForUsers` for the password hash, server `users.mutableUsers = false`
  (hash changes apply), SIGRTMIN to FTL after setup, unstable's setup script (26.05's fails on reruns, TODO 26.11),
  `--no-check-sigs` copy (server trusts `@wheel`), DNS check needs a real address (dig prints timeouts to stdout).
- eMMC flips mmcblk0/1 between boots -> disko by-path. `nix fmt` with no args hangs (pass files). Remote shell is fish.
- **Next: 7.4 (user) trial run** — point reason/deepthought DNS at `.2` in NetworkManager for a few days, note v6
  differences in design.md Risks. Then 8.5 (cutover runbook, assistant, before 8.2), then 8.2-8.4 (user), 9.x cleanup.
- Allowlist domains still unknown/missing in `pihole-allowlist.txt` (1 exact allowed domain shows in gravity: check).

## Session 2026-10-18 evening (deepthought) — READ FIRST
**Progress 16/30** (4.2, 4.3, 7.1 done). **Install NOT yet run.** State:
- `secrets/dumont.yaml` complete (host key, `users_yori_password_hash`, `pihole_web_password`, `pihole_inventory`).
  Full dumont build passes, `sops.defaultSopsFile` = dumont.yaml. Uncommitted: that file, `disko.nix`, runbook (staged), tasks.
- **disko fix:** Wyse eMMC is `mmcblk1` (14.7 GB), now `/dev/disk/by-path/platform-80860F14:00`. No firmware errors on installer.
- `docs/runbooks/dumont-install.md` written (7.1). Install = `nixos-anywhere --phases disko,install,reboot` against the
  booted installer (installer root pw was temporary `test`, ssh `root@<installer-ip>`; IP was .229 via DHCP, may change).
  Must stage host key from sops via `--extra-files` (see runbook), `--generate-hardware-config` overwrites placeholder
  -> review + commit it afterwards.
- **Next (user):** run install (7.2), then assistant runs read-only dig/ssh checks. Then 6.1/6.2 deploy app + runbook, 8.5.
- Wintermute facts (read via `ssh server`, no sudo needed for /etc/pihole): DHCP range `.12-.254`, 24h, router `.1`,
  Quad9 upstreams, DNSSEC on, wintermute hands out `.3` + its IPv6 as DNS. dumont placeholder range `.100-.250` must become
  `.12-.254` (task 8.1, TODO in pihole.nix). Inventory includes 4 `cname=` lines (emby/duplicati/pihole/traefik) beyond plan.
  Also still to add: the 2 allowlist domains (unknown to the assistant) in `pihole-allowlist.txt`.
- On reason nix hangs on dead `attic.xuyh0120.win`; use `--option substituters "https://cache.nixos.org/" --option connect-timeout 5`.

---


**Status (2026-10-18):** implementation paused at **13/30 tasks**, with 1.1, 2.1–2.4, 3.1–3.3, 4.1 and 5.1–5.4 done.
**Code committed and pushed as `f90a5d3`**, rebased onto `origin/main` after `2e303f8` (desktop kernel CachyOS → Zen,
because of xddxdd's cache compromise). The Zen kernel now lives in `hostgroups/desktop/modules/boot.nix`, and the
desktops were re-verified as package-order-only (design.md D2). Still uncommitted: the planning-file edits
(`proposal.md`, `design.md`, `tasks.md`, `specs/host-profiles/spec.md`), plus the untracked `baseline-drvpaths.txt`
(use its **last** entries) and this file. A copy of all of it is in `~/Dokumente/Intstallation_Dumont/` (wintermute
share, reachable from deepthought).

**On reason, nix hangs on the dead `attic.xuyh0120.win` cache** (it resolves to a black-hole address) until reason is
rebuilt. Add `--option substituters "https://cache.nixos.org/ https://vicinae.cachix.org" --option connect-timeout 5`
to nix commands there.

**Resume with:** `/opsx:apply add-dumont-pihole-host`. The next assistant task is **6.1** (the deploy app). The user's
part, **4.2**, can happen in parallel, and **4.3** can only be verified after 4.2.

## Where implementation stands (2026-10-15)

**Done and verified:**
- **Shared split (2.1–2.4).** Docker, scx, the desktop kernel (Zen)/Plymouth/quiet boot, Stylix, nerd-fonts, dconf, the
  electron exception, the desktop user groups and the KeePassXC/KeeShare sops template moved from `system/shared`
  to `system/hostgroups/desktop`.
  - The desktops' drvPaths changed **only from package-list order**, proven with `nvd` (reason, both built) and at
    derivation level (deepthought). Details are in design.md D2.
  - The new baseline is the second block in `baseline-drvpaths.txt`. Every later step kept both desktops
    **IDENTICAL** to it.
  - `mkHost` has `homeManager ? true`. `fleet.sops.perHostKey` exists. CLAUDE.md is updated. `nix flake check`
    passes.
- **Server hostgroup + dumont (3.1–3.3).**
  - `system/hostgroups/server`: networkd, no docs/nix-index, zram, min/max-free GC, `configurationLimit = 5`,
    journald 200M, no flake-registry nixpkgs pin.
  - `system/hosts/dumont`: disko on `/dev/mmcblk0`, placeholder `hardware-configuration.nix`, firmware trimmed to
    `rtl_nic` + `i915`, static `.2`/`::2`, firewall.
  - The flake gained a `disko` input, imported only by dumont. `flake.lock` is modified by that.
  - Closure: **1.5 GiB, 693 paths**, with no desktop parts (it was 2.5 GiB before the firmware/registry trim).
- **Secrets (4.1).**
  - `.sops.yaml` has dumont's age recipient and a `secrets/dumont.yaml` rule (dumont + shared).
  - `secrets/dumont.yaml` holds only `ssh_host_ed25519_key`, the private host key, encrypted. Its public half is
    `system/hosts/dumont/ssh_host_ed25519_key.pub`.
  - Verified with the key before it was shredded: dumont's identity decrypts the file and is **refused** on
    `shared.yaml`.
  - dumont sets `fleet.sops.perHostKey = true` (`modules/secrets.nix`).
- **Pi-hole (5.1–5.4).** `modules/pihole.nix`:
  - FTL v6 settings with DHCP **off**.
  - Lists: StevenBlack + HaGeZi Pro, plus `pihole-allowlist.txt`, which is only added while it has a domain.
  - Inventory via `sops.secrets.pihole_inventory`, read through `conf-file=`.
  - Web password via the `pihole_web_password` → `FTLCONF_webserver_api_password` EnvironmentFile.
  - The rendered `pihole.toml` contains no MAC or password.
  - All open questions about FTL keys were answered from FTL's source (design.md D7, "Resolved during tasks
    5.1–5.4").

**Build status:** dumont only builds with `sops.validateSopsFiles = false`, because `secrets/dumont.yaml` lacks the
user's keys (4.2). Build command used for verification:
```
nix build --no-link --print-out-paths --impure --expr '((builtins.getFlake (toString ./.)).nixosConfigurations.dumont.extendModules {modules = [{sops.validateSopsFiles = false;}];}).config.system.build.toplevel'
```
Desktop check: compare `nix eval --raw .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath` for reason
and deepthought against the **last** entry per host in `baseline-drvpaths.txt`. (The helper script lived in the
session scratchpad and is gone.)

**Next for the assistant: task 6.1, the `deploy-dumont` flake app.** Already found for 26.05's `nixos-rebuild-ng`:
- `--target-host` and `--sudo` exist; `--ask-sudo-password`/`-S` implies `--sudo`. `--use-remote-sudo` is gone.
- `--use-substitutes` lets dumont fetch from cache.nixos.org instead of copying everything from the deployer.
- Record these in design.md's Open Questions when doing 6.1.
- Pin `system/hosts/dumont/ssh_host_ed25519_key.pub` as known host (`UserKnownHostsFile` + `StrictHostKeyChecking=yes`)
  in the app.

After 6.1: 6.2 (deploy runbook), 7.1 (install runbook, which must cover staging the host key from sops into
`--extra-files` and `--generate-hardware-config nixos-generate-config ./system/hosts/dumont/hardware-configuration.nix`,
plus `dmesg | grep -i firmware` on the installer), then 8.5 (cutover runbook).

**The user's part, 4.2:** add to `secrets/dumont.yaml`. Editing needs the root-only shared key:
`sudo SOPS_AGE_KEY_FILE=/var/lib/sops/age/keys.txt sops secrets/dumont.yaml`
- `users_yori_password_hash`: from `mkpasswd -m yescrypt`
- `pihole_web_password`: plaintext
- `pihole_inventory`: a multi-line block of raw dnsmasq lines, `dhcp-host=<mac>,<ip>,<name>` and
  `host-record=<name>.meine2cent.home,<ip>` (or `address=`). Taken from wintermute's
  `/etc/pihole/dnsmasq.d/04-pihole-static-dhcp.conf` and `/etc/pihole/custom.list`; deduplicate the two `sv08`
  records.

Also add the two allowlist domains (public, not secret) to `system/hosts/dumont/modules/pihole-allowlist.txt`. Then
4.3 is verified by building `.#nixosConfigurations.dumont.config.system.build.toplevel` **without** the override, and
by checking that `sops.defaultSopsFile` is `dumont.yaml`.

**Open placeholders to resolve in 8.1:** DHCP `start`/`end`/`leaseTime` (currently `.100–.250`, 24h) and the
upstreams (currently Quad9). Both are marked `TODO(task 8.1)` in `pihole.nix`.

**Small things noticed:**
- The pulled-in KeeShare commit had put `keepassxc.nix` into `shared`, so dumont would have requested a desktop
  secret. It's fixed by the move (the path to the ini gained one `../`).
- The pi-hole module's list setup only adds lists, never removes them (design.md D7).

---

*Original planning-session handoff below (2026-10-14).*

This repo is public. Keep MACs, IPv6 prefixes/interface IDs, passwords and the device inventory out of every file
here, including this one.

## What was decided, and why

All decisions came out of a grill-me interview with the user. design.md records them as D1–D10. This is the short
form, plus the reasoning that isn't obvious from the design.

| Topic | Decision | Not obvious |
|---|---|---|
| Pi-hole | v6 on the native `services.pihole-ftl`/`pihole-web` | The user lifted the old "leave the v5 pin alone" rule for this. v6 is current upstream (FTL 6.7.1), and nixos-26.05 matches it. |
| Flake | Split `system/shared`, new `server` hostgroup, `mkHost` gets `homeManager` + `stateVersion` | reason/deepthought drvPaths must not change (task 1.1 → 2.x) |
| Install | nixos-anywhere + disko against the booted installer ISO | Avoids kexec, which needs RAM that 2 GB may not have |
| Secrets | dumont's own age identity from its SSH host key | The shared key decrypts CIFS creds, KeeShare key and desktop password hashes. It must never land on dumont. |
| Names | Host `dumont`, user `yori` | Tron: guardian of the I/O Tower, and the program who gets him to open it. The user chose these over babelfish/heimdall. |
| Address | Static `192.168.1.2`, IPv6 token `::2` | `.3` is wintermute's own address (Samba/SSH use it). An EUI-64 address would leak the MAC. |
| Config | Settings in Nix, inventory and web password from sops at runtime | Everything in `settings` lands in a world-readable store file. The UI is read-only (`misc.readOnly`, module default). |
| Deploy | `nix run .#deploy-dumont`: `test` → health checks by IP → `switch`, or revert | The boot default only moves after the checks pass, so a power cycle means rollback. |
| Cutover | Trial run (reason only) → shorten leases → DHCP off on wintermute **while its DNS keeps running** → dumont DHCP on, Speedport repointed → wintermute to 0 after a quiet lease period | Clients renew unicast to `.3`. Killing `.3` outright would leave devices without DNS for up to ~21 h with 24 h leases. |
| Scope | Monitoring, secondary DNS, deploying from wintermute, HTTPS and auto-updates are follow-ups | Listed in design.md → Follow-ups. Task 9.3 copies them into `docs/hosts.md`. |

## Open items to verify early

These are listed in design.md → Open Questions. The ones most likely to force a fallback:

- whether `conf-file=<sops path>` is accepted in `misc.dnsmasq_lines` (fallback: `/etc/dnsmasq.d` +
  `misc.etc_dnsmasq_d`)
- whether `FTLCONF_webserver_api_password` from an `EnvironmentFile` works with `readOnly`
- whether `file://` lists are accepted for the allowlist
- the remote-sudo flags of `nixos-rebuild` in 26.05

## Things that tripped up the planning session

- **Reading wintermute's Pi-hole state:** `kubectl --context wintermute … exec` was blocked by the permission
  classifier. Lease time and DHCP range are still unknown and are needed before phase 3 (task 8.1). Ask the user to
  run it with `!`. The command is read-only, and its output contains reservation lines, so don't paste it into the
  repo:
  ```
  kubectl --context wintermute -n pihole exec deploy/pihole-deployment -- sh -c "grep -E '^DHCP_' /etc/pihole/setupVars.conf; grep -c dhcp-host /etc/dnsmasq.d/04-pihole-static-dhcp.conf; grep -E '192\.168\.1\.2(,|$)' /etc/dnsmasq.d/04-pihole-static-dhcp.conf"
  ```
- **Rebuilds, installs, deploys and live changes** on wintermute or the Speedport are the user's job (CLAUDE.md).
  These are marked **(user)** in tasks.md.
- **The device inventory** (task 4.2) comes from wintermute's `04-pihole-static-dhcp.conf` and `custom.list`. It goes
  only into `secrets/dumont.yaml`. `sv08` has two conflicting A records there; deduplicate.
- **The Wyse is not set up yet.** BIOS USB boot, and whether only the EFI fallback path boots, are unverified on the
  real unit.

## Related

- History of the current wintermute setup: `docs/wintermute/pihole/README.md` (hostNetwork cutover, KSK-2024 hack,
  static-lease Save quirk) and the untracked `pihole_wintermute_handoff.md` at the repo root (reason only).
- Fleet table: `docs/hosts.md`. dumont is added in task 9.2.
