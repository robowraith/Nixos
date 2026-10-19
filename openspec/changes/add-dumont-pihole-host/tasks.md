# Tasks

Tasks marked **(user)** need sudo, the hardware, wintermute's UI or the Speedport. The assistant prints the exact
command or steps and waits for the result. Everything else is repo work plus read-only checks (`nix eval`,
`nix build`, `nix flake check`, `dig`, `ssh … systemctl status`).

## 1. Baseline for the shared split

- [x] 1.1 Record `nix eval --raw .#nixosConfigurations.{reason,deepthought}.config.system.build.toplevel.drvPath` into
  the change directory (`baseline-drvpaths.txt`), and verify that both evaluate on a clean tree.

## 2. Split `system/shared` and extend `mkHost`

- [x] 2.1 Move Docker, the desktop kernel (CachyOS, Zen since `2e303f8`) + `scx`, Plymouth/quiet boot, Stylix enablement/theme, nerd-fonts,
  `programs.dconf`, `permittedInsecurePackages` and the desktop user groups from `system/shared` into
  `system/hostgroups/desktop`. Verify that reason's and deepthought's drvPaths match `baseline-drvpaths.txt`. If they
  don't, explain the diff with `nix-diff` in design.md (D2) and show it has no package or service effect.
- [x] 2.2 Add `homeManager ? true` and per-host `stateVersion` handling to `mkHost`. Verify that both desktop
  drvPaths are still unchanged and that `nix flake check` passes.
- [x] 2.3 Make `system/shared/modules/sops.nix` support a per-host key option (D4) without changing the default.
  Verify that the desktop drvPaths are unchanged.
- [x] 2.4 Update CLAUDE.md's Architecture section (shared vs. desktop vs. server, `homeManager` flag, per-host sops),
  and verify that it matches the code.

## 3. `server` hostgroup and dumont host skeleton

- [x] 3.1 Create `system/hostgroups/server` with:
  - systemd-networkd
  - the LTS kernel
  - documentation off
  - zram
  - journald cap
  - GC `min-free`/`max-free`
  - `configurationLimit = 5`

  Verify by evaluating a throwaway host that imports it.
- [x] 3.2 Create `system/hosts/dumont/` with:
  - the disko layout (ESP ~512 MB + ext4)
  - a `hardware-configuration.nix` placeholder generated for the Wyse 3040 (Atom/eMMC modules: `sdhci_acpi`,
    `mmc_block`, `xhci_pci`, `usb_storage`)
  - static `192.168.1.2/24` networking with `IPv6Token=::2`
  - the firewall ports from D6

  Add the disko input to the flake, and register `dumont = mkHost {hostname = "dumont"; username = "yori";
  homeManager = false; stateVersion = "26.05";}`. Verify that `nix build .#nixosConfigurations.dumont.config.system.build.toplevel`
  succeeds on reason. Until the secrets exist (4.x), verify with `sops.validateSopsFiles = false` via `extendModules`. The full build, including the sops manifest, is part of 4.3.
- [x] 3.3 Verify the closure against host-profiles: `nix path-info -r` on dumont's toplevel contains no docker, no
  home-manager generation, no Xorg/Wayland session and no desktop kernel. Record the closure size in design.md.

## 4. Per-host secrets for dumont

- [x] 4.1 Generate dumont's ed25519 host key on reason in the scratchpad, never in the repo tree. Derive its age
  recipient with `ssh-to-age`, and add a `secrets/dumont\.yaml$` creation rule to `.sops.yaml` with dumont's and the
  shared recipients. Verify with `sops updatekeys --help` that the rule matches.
- [x] 4.2 **(user)** Complete `secrets/dumont.yaml` (the assistant already encrypted the host private key into it during 4.1, so the key never passed through a terminal; verified that dumont's identity decrypts it and is refused on `shared.yaml`) by adding:
  - `users_yori_password_hash` (`mkpasswd -m yescrypt`)
  - the Pi-hole web password
  - the inventory (reservations as MAC/IP/name, and local records)

  The inventory is taken from wintermute's `04-pihole-static-dhcp.conf` and `custom.list`, deduplicated (e.g. the
  `sv08` A record that exists twice). Verify that `sops -d` works on reason, and that `git grep -E '([0-9a-f]{2}:){5}'`
  finds nothing new.
- [x] 4.3 Wire dumont to the per-host sops option and `users_yori_password_hash`. Verify that dumont's toplevel builds,
  and that `secrets/shared.yaml` is not referenced by dumont's config (`nix eval` of `sops.defaultSopsFile`).

## 5. Pi-hole v6 configuration

- [x] 5.1 Look up the v6 `pihole.toml` keys for: interface, listening mode, upstreams, DNSSEC, domain, DHCP
  range/router/lease time, authoritative mode, IPv6 DHCP/RA off and `database.maxDBdays`. Record the chosen keys in
  design.md (D7 / Open Questions).
- [x] 5.2 Configure `services.pihole-ftl` and `services.pihole-web` (port 80) with `dhcp.active = false`, and set
  `lists`: StevenBlack + HaGeZi Multi PRO, plus the allowlist file. Verify the build, and that the rendered
  `pihole.toml` in the store contains no MACs or passwords.
- [x] 5.3 Add the sops template `pihole-inventory.conf` (owner `pihole`, `restartUnits`) loaded via `conf-file=` in
  `misc.dnsmasq_lines`. Fallback: `/etc/dnsmasq.d` with `misc.etc_dnsmasq_d`. Verify the build. Behaviour is verified
  in 7.2.
- [x] 5.4 Provide the web password through an `EnvironmentFile` from sops (`FTLCONF_webserver_api_password`), and
  verify the build. Login is verified in 7.2.

## 6. Guarded deploy command

- [x] 6.1 Implement `apps.x86_64-linux.deploy-dumont` (`writeShellApplication`) as specified in D8: test →
  health checks with retry → switch, or revert to the recorded generation and exit 1. It uses only
  `yori@192.168.1.2`. Verify with `nix run .#deploy-dumont -- --help`, and with `shellcheck` passing through
  `writeShellApplication`.
- [x] 6.2 Write `docs/runbooks/dumont-deploy.md`: usage, what each check means, manual rollback by IP, and
  power-cycle as last resort. Verify that every command in it matches the app's actual flags.

## 7. Install and trial run (phases 1–2)

- [x] 7.1 Write `docs/runbooks/dumont-install.md`:
  - BIOS settings / USB boot on the 3040
  - booting the minimal ISO and enabling SSH
  - the `nixos-anywhere --flake .#dumont --extra-files <dir> root@<installer-ip>` command, with how to stage the host
    key from sops into `<dir>`
  - first-boot checks

  Verify the command against `nixos-anywhere --help`.
- [x] 7.2 **(user)** Install dumont per the runbook. Then verify from reason, with the assistant running read-only
  checks:
  - `dig @192.168.1.2` example.com / doubleclick.net / an inventory name / `dnssec-failed.org` (SERVFAIL)
  - the same over `<ula-prefix>::2`
  - web UI login
  - `sops` secrets present under `/run/secrets`
  - no `/var/lib/sops/age/keys.txt` on dumont
  - `df -h /` and the ESP usage
- [ ] 7.3 **(user)** Run `nix run .#deploy-dumont` once with a harmless change, then once with a deliberately broken
  inventory line on a throwaway branch. Verify that the first one switches, and that the second one reverts and exits
  non-zero with DNS answering throughout.
- [ ] 7.4 **(user)** Trial run: point reason (and optionally deepthought) at `192.168.1.2` in NetworkManager for a few
  days. Note any v6 differences in design.md under Risks, and fix or decide on each before phase 3.

## 8. Cutover (phase 3)

- [x] 8.1 **(user)** Read wintermute's current `DHCP_*` values (lease time, range) and confirm that `.2` is outside
  the range and not reserved. Copy the range into dumont's settings. Verify that dumont's config matches.
- [ ] 8.2 **(user)** Shorten wintermute's lease time to 1 h (UI → Save), then wait at least one *old* lease period.
- [ ] 8.3 **(user)** Run the handover:
  1. Turn off wintermute's DHCP (UI → Save), leaving its DNS running.
  2. Deploy dumont with `dhcp.active = true`.
  3. Repoint the Speedport (DNSv4 `.2`, DNSv6 `<ula-prefix>::2`).

  Verify:
  - a reconnected reserved device gets its IP, DNS `.2` and gateway `.1`
  - `rdisc6 enp7s0` shows only `fe80::1`
  - queries via `fe80::1` appear on dumont
  - client IPs in the query log are real
- [ ] 8.4 **(user)** Once wintermute's query log has been quiet for a lease period, scale `pihole-deployment` to 0,
  and verify that LAN DNS still works from a non-desktop device.
- [ ] 8.5 Write `docs/runbooks/dumont-cutover.md` with the phase 3 steps and the rollback order from the design.
  Verify it is complete against design.md's Migration Plan *before* 8.2 starts.

## 9. Cleanup and docs (phase 4, after ~2 weeks stable)

- [ ] 9.1 **(user)** On wintermute:
  - delete the Pi-hole k3s objects
  - remove the `.4` secondary address and the `pi.hole` PTR
  - remove `/etc/pihole/dnsmasq.d/99-root-ksk-2024.conf`

  Verify that `kubectl --context wintermute get ns pihole` is gone and that LAN DNS is unaffected.
- [ ] 9.2 Mark `docs/wintermute/pihole/README.md` as historical, with a pointer to dumont. Update `docs/hosts.md`:
  dumont row, wintermute's services without Pi-hole, and the Pi-hole notes moved to dumont. Verify that no IPv6
  interface IDs or MACs are added.
- [ ] 9.3 Record the design's Follow-ups (monitoring with its open alert-channel question, secondary DNS, deploy from
  wintermute, HTTPS, unattended updates) in `docs/hosts.md` under a "Planned" section, so they survive archiving.
  Verify that each one has enough context to start from.
- [ ] 9.4 Fold the root-level `pihole_wintermute_handoff.md` into `docs/` (history only, no MACs), and drop the
  Pi-hole items from the auto-memory index. Verify that `git status` shows no Pi-hole handoff left at the repo root.
