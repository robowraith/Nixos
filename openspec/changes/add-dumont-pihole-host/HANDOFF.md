# Handoff — add-dumont-pihole-host

## Live state verified 2026-10-25 (deepthought)

dumont: up 2d21h (last boot 2026-10-22 ~18:15), `running`, no failed units, `pihole-ftl` active, clock correct and
NTP synced, 0 FTL errors/warnings this boot, RAM 1.9 GB (1.2 free), `/` 17% used, generation `system-9` (26.05.20261018).
DNS/blocking/local names/web `/admin/` OK from deepthought. deepthought trial still active (`Desire`, resolv.conf
= .2). Not checked: whether the CMOS battery was replaced (the 10-22 boot synced fine either way), DHCP state
(`/etc/pihole` not readable as yori; config says off), reason's DNS.

## Handover done 2026-10-26 (deepthought) — READ FIRST

- **8.3 done:** wintermute DHCP off 17:33 (`pihole -a disabledhcp` in the pod via kubectl, UI is limited to reason);
  dumont `dhcp.active = true` deployed (`42da8b4`), listening on :67. Speedport DNS: primary dumont (v4 + ULA),
  **secondary wintermute's Pi-hole** (`192.168.1.3` + its EUI-64 ULA) instead of Quad9. wintermute is still v5 and
  will be reinstalled as v6; it must then get dumont's inventory + allowlist, no DHCP.
- **Checks passed:** :53/:67 up; only the Speedport sends RAs (route table, `rdisc6` needs root); DNS via
  `fe80::1` works and blocks; dumont dashboard shows real client IPs (deepthought `.50` top) and 3 active leases
  (`.50`, `.140` = phone, `.158`).
- **Open:** reason (reserved `.111` lease, DNS `.2`; `nmcli device reapply enp7s0`), local-name resolution on a
  phone, 8.4: scale wintermute Pi-hole to 0 once its query log has been quiet 1 h (only Speedport), then 7.4
  trial override removal on deepthought (`nmcli con mod Desire ipv4.dns "" ipv4.ignore-auto-dns no
  ipv6.ignore-auto-dns no`) so it takes `.2` via DHCP. dumont leases are 24 h again.
- **Open: Speedport DNS and `.meine2cent.home` (found 2026-10-26).** `dig A emby.meine2cent.home @fe80::1` (and
  `wintermute.meine2cent.home`) returns an authoritative (`aa`) NOERROR with 0 answers; AAAA returns only the
  CNAME; public names are fine. The same names resolve correctly from dumont (`.2`, ULA) and wintermute. A client
  that sends its DNS queries to the Speedport (IPv6 RDNSS from the RA) gets no A for local names. Unknown whether
  this predates the cutover. Phone: emby worked in Chrome, failed in Firefox (suspect `network.trr.mode`, left to
  the user). Fix idea: hand out DNS only via DHCP, or check the Speedport's own domain handling.
- **Plan updated 2026-10-26** (tasks.md, design.md, runbook): 8.4 dropped (wintermute stays up as secondary), new 8.6
  (remove deepthought override, verify reason), new 8.7 (v6 reinstall), 9.1 waits for 8.7. Kubectl context is `home_cluster`.
- **Plan updated 2026-10-29:** DHCP cold standby on wintermute (design D11, spec requirement "Cold-standby DHCP on
  wintermute", tasks 8.8–8.10). Not a live second server: DHCP stays off on wintermute, turned on by hand only while
  dumont is down. Next: 8.9 runbook; 8.10 lease-time decision is the user's.

## Cutover started 2026-10-25 15:15 (deepthought)

- **8.2 done:** wintermute lease time set to 1 h at 15:15 (via `kubectl --context home_cluster -n pihole exec
  deploy/pihole-deployment -- pihole -a enabledhcp 192.168.1.12 192.168.1.254 192.168.1.1 1 meine2cent.home`).
  setupVars + `02-pihole-dhcp.conf` show 1/`1h`; DNS up. The command blanked `DHCP_IPv6`/`DHCP_rapid_commit`;
  restored to `false`. **Earliest handover (step 2): 2026-10-26 ~15:20.** Remember to set the lease back (runbook
  Rollback step 4) only if rolling back.
- wintermute's `/admin` is deliberately limited to `192.168.1.111` (reason): ConfigMap `pihole-php-cve-2026`,
  PHP CVE mitigation; others get 403. Use reason for the UI. kubectl context for wintermute is `home_cluster`.
- Trial on reason skipped by decision. CMOS battery replaced (user, 2026-10-25).

## Update 2026-10-22 (deepthought)

- **Pi-hole tested from deepthought (all pass):** ping 0% loss ~4 ms; resolve (A+AAAA); blocking (doubleclick.net,
  ads.google.com -> 0.0.0.0); DNSSEC `ad` flag set, dnssec-failed.org -> SERVFAIL; TCP DNS; local names (pi.hole,
  dumont/wintermute.meine2cent.home, reverse of .3); allowlist domains resolve (opendistrocommunity.dev has no
  records, same at Quad9, not blocked); web `/admin/` 302; dnsmasq-pi-hole-v2.93; cached 3 ms, uncached ~200 ms.
  **Not tested:** DHCP (off), non-LAN source refusal (`listeningMode = LOCAL`).
- **7.4 trial started on deepthought:** NM profile `Desire` (wifi): `ipv4.dns 192.168.1.2`,
  `ipv4.ignore-auto-dns yes`, `ipv6.ignore-auto-dns yes` (so the Speedport RA DNS `fe80::1` can't bypass blocking).
  Imperative nmcli, not in Nix, deliberately. Undo: `nmcli con mod Desire ipv4.dns "" ipv4.ignore-auto-dns no
  ipv6.ignore-auto-dns no && nmcli con up Desire`. Other profiles (wired, work networks) untouched.
  Note IPv6/other differences in design.md Risks as they show up.

## Current state (2026-10-19 evening) — READ FIRST

**Pick up on reason or deepthought:** everything is committed and pushed except this file (last main commit before 10-25: `242aa80`). `git pull` in `~/nixos`,
then `/opsx:apply add-dumont-pihole-host`. No files outside git are needed any more (the `~/Privat/…` /
`~/Dokumente/…` copies are obsolete). Both desktops can deploy dumont: the deploy app pins dumont's host key itself.
- **reason:** not rebuilt since 2026-10-18. Until it is, nix may hang on the dead `attic.xuyh0120.win` cache; add
  `--option substituters "https://cache.nixos.org/" --option connect-timeout 5`. Its rebuild picks up the
  `neededForUsers` change (password file moves to `/run/secrets-for-users/`) and the `ssh dumont` entry.
- If the pre-commit hook points at a missing store path, run `nix develop -c true` once.

**Progress 22/30.** dumont (Wyse 3040) runs at 192.168.1.2: DNS + blocking + local names, DHCP configured but OFF.
- Deploy: `nix run .#deploy-dumont` (asks yori's sudo password first). Verified: healthy deploy switches; broken one
  (unreachable upstream) reverts and exits 1. `ssh dumont` works after a desktop rebuild.
- Hardened: nftables, SSH/DNS/web only from 192.168.1.0/24, fe80::/10, fc00::/7 (public IPv6 blocked, tested);
  `AllowUsers yori`; key-only SSH. fail2ban deliberately skipped (key-only, LAN-only, RAM).
- Allowlist in `pihole-allowlist.txt` (3 domains from wintermute). Lists are only ever added, never removed:
  dropping a domain needs the dashboard (Lists) or a reinstall. Dashboard = view + quick tests; settings come from Nix.
- Fixes found on the way (all pushed): `neededForUsers`, server `mutableUsers = false`, SIGRTMIN after setup,
  unstable's setup script (TODO 26.11), setup `RemainAfterExit`, `--no-check-sigs` + `@wheel` trusted, DNS check
  needs a real address. eMMC flips mmcblk0/1 -> disko by-path. Remote shell is fish (wrap in `sh -c`).

- **CMOS battery replaced (user, 2026-10-25).** Was dead (2026-10-19): every cold boot started in 2018 -> DNSSEC fails -> all DNS SERVFAIL until NTP
  syncs. Fixed by NTP via PTB IPs (`networking.nix`). If ever stuck: set the clock from a desktop,
  `ssh -t yori@192.168.1.2 sudo date -s @(date +%s)` (fish; NOT inside a dumont shell, there `date` is 2018). A deploy
  while dumont's DNS is down fails (substituters unresolvable, daemon disconnects), so fix the clock first.
  Replacement: CR2032 with 2-pin 1.0 mm lead (same as HP EliteBook CMOS battery); check polarity against the old one.
  Case opens by clips from the rear corner slot by the power socket; battery taped at the board's upper left.
  Sources: Dell 3040 manual (coin battery removal), parkytowers.me.uk/thin/wyse/3040/, mcgarrah.org.

**Next:**
1. **7.4 (user) trial run:** deepthought running since 2026-10-22 (see above, no issues so far). reason still to do:
   DNS -> `192.168.1.2` in NetworkManager. Note IPv6 differences in design.md Risks.
2. **Hardware (user):** ~~replace CMOS battery~~ done (2026-10-25); verify a cold boot keeps the clock. BIOS: AC Recovery -> Power On, so a power cut does not leave the LAN without
   DNS/DHCP. Headless boot not yet observed.
3. **8.2–8.4 (user) cutover** per `docs/runbooks/dumont-cutover.md` (8.1 + 8.5 done).
4. **9.x cleanup** after ~2 weeks stable.

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

- [x] `conf-file=<sops path>` accepted in `misc.dnsmasq_lines` (2026-10-24: FTL loads it, local names resolve
  via dumont)
- [x] `FTLCONF_webserver_api_password` from an `EnvironmentFile` with `readOnly` (2026-10-24: dashboard login works)
- [x] `file://` allowlist (2026-10-24: dashboard shows it enabled, type Allow, "unchanged upstream"; every edit of
  the file adds a new store-path entry, delete the stale one in the dashboard)
- [x] remote-sudo flags of `nixos-rebuild` in 26.05 (`deploy-dumont` works, verified 2026-10-18)
- [ ] authoritative DHCP key: only testable once `dhcp.active = true` (cutover)

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
