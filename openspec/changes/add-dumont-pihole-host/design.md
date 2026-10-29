# Design

## Context

See proposal.md for the motivation. Constraints that shape the approach:

- **Hardware:** Dell Wyse 3040: Atom x5-Z8350 (x86_64), 2 GB RAM, 8 GB eMMC, one wired NIC, UEFI, no BMC.
  Evaluating the flake on the box is impractical, and storage is the tightest resource.
- **Flake today:** `mkHost` always imports `system/shared` (Docker, the CachyOS LTO kernel (Zen since `2e303f8`, 2026-10-16) + `scx`, Plymouth, Stylix,
  nerd-fonts) and wires Home Manager with the user's full dotfiles. `stateVersion` defaults to `"25.11"`.
  `system/shared/modules/sops.nix` hardcodes `secrets/shared.yaml` and the shared age key file. `users.nix` adds
  desktop groups (`docker`, `networkmanager`, `audio`, …).
- **Network today:** wintermute (`192.168.1.3`, plus secondary `.4` = `pi.hole`) runs Pi-hole v5 (`2024.07.0`) on
  k3s with `hostNetwork`. DHCP hands out `.3` as DNS server. The Speedport forwards its own DNS (v4: `.3`, v6:
  wintermute's ULA) to Pi-hole, and there is no fallback resolver. `.2` is unused. The domain is `meine2cent.home`.
- **Repo is public on GitHub.** The domain and private IPv4 addresses are already in tracked files. MACs and the device
  inventory are not, and must stay that way. An EUI-64 IPv6 interface ID encodes a MAC.
- **CLAUDE.md:** rebuilds need sudo and are always run by the user.
- **Native module (`nixos/modules/services/networking/pihole-ftl.nix`, 26.05):**
  - `settings` is rendered to a store `pihole.toml`, so it is world-readable and ends up in this public repo's
    closure.
  - `misc.readOnly` defaults to `true`, which blocks config changes through the API/UI.
  - `lists` are loaded into gravity by a `pihole-ftl-setup` oneshot. That needs `webserver.api.cli_pw = true` if
    set.
  - The settings file path is passed as `PIHOLE_CONFIG`, so any settings change restarts FTL.
  - `misc.dnsmasq_lines` is an escape hatch for raw dnsmasq directives.
- **Versions:** FTL 6.7.1 and web 6.6 in nixos-26.05 match upstream's latest. Core is 6.4.2 (upstream 6.4.3).

## Goals / Non-Goals

**Goals:**
- dumont replaces wintermute as the LAN's DNS/DHCP server with no lasting behaviour regression, and with a rollback
  path until cleanup.
- Every Pi-hole setting is reproducible from the repo without publishing the device inventory.
- The shared-layer split leaves reason and deepthought byte-for-byte unchanged, or the differences are explained.
- A failed deploy costs seconds of DNS, not hours.

**Non-Goals:**
- Redundant DNS, monitoring/alerting, HTTPS for the web UI, unattended updates, and deploying from wintermute. See
  [Follow-ups](#follow-ups).
- Migrating Pi-hole's query history or current DHCP leases.
- Any change to Emby, Duplicati, Samba or k3s on wintermute beyond removing Pi-hole.

## Decisions

### D1 — Pi-hole v6 on the native NixOS modules
`services.pihole-ftl` + `services.pihole-web`, running directly on the host.
- **Why:** declarative config in git ends the drift; no container runtime on 8 GB; v6 ships the KSK-2024 anchor; it
  is current upstream.
- **Alternative:** the v5 image in `oci-containers` with host networking. Smaller behaviour change, but imperative
  `/etc/pihole` state, podman on the eMMC, and the KSK hack would remain.
- **Risk:** the earlier v6 upgrade failed for reasons that were never recorded. This is mitigated by the trial run
  (Migration Plan, phase 2), with wintermute's v5 left untouched as the fallback.

### D2 — Split `system/shared`; add a `server` hostgroup; Home Manager optional
- **`system/shared` keeps:** nix settings + GC, nix-index, sops, ssh, users (base groups only), localization, the
  base CLI packages, firewall.
- **Moved to `system/hostgroups/desktop`:** Docker, `boot.nix`'s Plymouth/quiet-boot/desktop kernel (Zen), `scx`, Stylix
  enablement and theme, nerd-fonts, `programs.dconf`, the electron `permittedInsecurePackages`, and the desktop user
  groups (appended via list merge in the desktop group).
- **`mkHost` gains:**
  - `homeManager ? true`, which gates the HM module block and `users.${username}`.
  - Passing `stateVersion` per host (dumont: `"26.05"`).
- **Stylix:** the module stays imported in `mkHost` (it must be evaluable), but `stylix.enable` moves to the desktop
  group, so servers evaluate with Stylix disabled.
- **New `system/hostgroups/server`:** headless defaults, i.e. systemd-networkd instead of NetworkManager, no
  documentation, the stock LTS kernel, GC tuned for small disks (D9).
- dumont imports `shared` + `server`, and **not** `home`: that group brings NetworkManager and CIFS mounts of
  wintermute's shares.
- **Invariant:** record reason's and deepthought's `config.system.build.toplevel.drvPath` before the split and require
  them to be identical after. Unavoidable ordering differences (e.g. in `extraGroups`) must be shown with
  `nix-diff`/`nvd` to have no package or service effect, and written into this design.
- **Alternative:** `mkForce`-overrides on dumont only. Rejected: every new desktop setting in `shared` would leak onto
  servers by default.
- **Recorded result (task 2.1, 2026-10-15):** the drvPaths changed for both desktops. Cause: moving `docker-compose`
  and `nerd-fonts.fira-code` from `shared` into `desktop` changes the order of `environment.systemPackages`. That
  re-hashes `system-path` and its 15 dependants (`etc`, `dbus-1`, `man-paths`, `system-units`, `user-units`, the
  polkit/dbus-broker/mandb units, fish completions, `activate`, toplevel). Evidence:
  - **reason, built both toplevels:** `nvd diff` reports "No version or selection state changes", 3241 → 3241
    paths. The `sw` and `etc` trees are entry-for-entry identical apart from those self-hashes, and `system-path`'s
    references are identical.
  - **deepthought, derivation level:** the same 16 derivations change. `system-path`'s input references are
    identical (same set), and its derivation differs only in its own output path.
  - **`extraGroups`:** the `wheel` + desktop groups split re-hashed nothing.

  New baseline after 2.1: reason `7c5vhsjibvql5vn7pw75jmlg9g8xf569`, deepthought `zmnydrjmpg9bbwi27rb5pa1iq94l2pgm`.
  Tasks 2.2 and 2.3 must keep these identical.
- **Rebase onto `2e303f8` (2026-10-18):** `origin/main` switched the desktop kernel from CachyOS to Zen (xddxdd's
  cache compromise) in `shared/boot.nix`. The rebase moved that Zen kernel, with its comment, into
  `hostgroups/desktop/modules/boot.nix`. Re-verified against the new `origin/main` (`c04a34f`): for both desktops the
  same 16 derivations change, `system-path`'s input set is identical, and the kernel is not among the changed
  derivations, so the result is the same package-order-only difference as above. dumont still builds (LTS 6.18,
  1.5 GiB) and `nix flake check` passes. The pushed result is `f90a5d3`. New baseline (the post-rebase entries in
  `baseline-drvpaths.txt`): reason `vvavhvrhv42k0gd3lj028xxpv4as7mby`, deepthought `cjrjvw2sjfqm4528zczrwdmd46hi6yny`.
  - **Operational note:** reason's *running* `nix.conf` still lists `attic.xuyh0120.win`, which now resolves to a
    black-hole address, so nix hangs in SYN-SENT. Until reason is rebuilt, pass
    `--option substituters "https://cache.nixos.org/ https://vicinae.cachix.org" --option connect-timeout 5` to nix
    commands there.

- **Changed on purpose during task 7.2 (2026-10-19):** `system/shared/modules/users.nix` now sets
  `neededForUsers = true` on the password hash. Without it, a fresh install creates the user before sops decrypts the
  secret, so the user has no password (found on dumont). This moves the file to `/run/secrets-for-users/` and changes
  both desktop drvPaths, so `baseline-drvpaths.txt` is stale from here on.

- **Also during task 7.3 (2026-10-19):** the server hostgroup sets `users.mutableUsers = false`. With mutable users a
  changed password hash in sops is ignored for an existing account; dumont needed a hash fix after install.

### D3 — Install with nixos-anywhere + disko against the live installer
- Boot the NixOS minimal ISO from USB (monitor and keyboard needed once), then run `nixos-anywhere --flake .#dumont`
  from reason.
- Its built-in kexec path needs RAM headroom 2 GB may not reliably give. Targeting the already-running installer
  avoids kexec.
- The disko layout in the repo has a GPT ESP of ~512 MB (vfat) and an ext4 root on the rest. No swap partition;
  `zramSwap` instead (D9).
- `--extra-files` places the pre-generated `/etc/ssh/ssh_host_ed25519_key{,.pub}` (D4).
- **Alternative:** a manual `nixos-install` on the box. Rejected: slow or OOM on 2 GB, and an unrecorded disk layout.

### D4 — Per-host sops identity from the SSH host key
- Generate dumont's ed25519 host key on reason and keep the private key **only** inside `secrets/dumont.yaml`, so a
  reinstall can reuse it. Derive the age recipient with `ssh-to-age` and add it to `.sops.yaml` for
  `secrets/dumont\.yaml$`, alongside the shared key.
- `system/shared/modules/sops.nix` becomes conditional: hosts that set an option (e.g.
  `fleet.sops.perHostKey = true`) use `sops.defaultSopsFile = secrets/${hostname}.yaml`,
  `sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"]` and no `keyFile`. Others keep today's behaviour.
- `users.nix` reads the password hash from the host's default sops file. For dumont that is
  `users_yori_password_hash` in `secrets/dumont.yaml`.
- **Alternative:** copy the shared age key. Rejected: it would put CIFS credentials, the KeeShare key and both
  desktop users' password hashes on a LAN appliance.

### D5 — Hostname `dumont`, user `yori`
Tron's guardian of the I/O Tower and the program who talks him into opening it. `yori` gets `wheel` and the two
existing SSH public keys, with no Home Manager profile. Its sudo password is the one typed during deploys.

### D6 — Addressing
- **IPv4:** static `192.168.1.2/24`, gateway `.1`, set with systemd-networkd. dumont is the DHCP server, so it can't
  use DHCP itself.
- **Its own resolver:** `127.0.0.1`, with a public resolver as fallback in `networking.nameservers` order so dumont
  can still fetch blocklists if FTL is down. Verify that this does not leak LAN queries.
- **IPv6:** SLAAC from the Speedport's ULA and GUA prefixes, with `IPv6Token=::2`. The ULA address is then
  `<ula-prefix>::2`: predictable, matching `.2`, and it does not publish the MAC the way EUI-64 would. Privacy
  extensions are off for the token address.
- **Firewall:** 22/tcp, 53/tcp+udp, 67/udp, 80/tcp (web UI). Use the module's `openFirewallDNS`/`openFirewallDHCP`
  where they cover it.

### D7 — Pi-hole configuration split: public settings in Nix, inventory and password at runtime
- **Public, in `services.pihole-ftl.settings`:**
  - interface, listening mode, upstreams
  - DNSSEC on, domain `meine2cent.home`
  - DHCP range, router `.1`, lease time
  - `dhcp.ipv6 = false`, no RA, authoritative mode (verify the v6 key: dnsmasq's default is non-authoritative)
  - `misc.readOnly = true` (module default, kept explicit)
- **Lists:** `services.pihole-ftl.lists` = StevenBlack hosts + HaGeZi Multi PRO (the raw.githubusercontent URL, which
  is known to work), and the two allowlist domains as an allow-type list from a small file in the flake via
  `file://`. Verify that v6 accepts `file://` lists. The fallback is `misc.dnsmasq_lines` / `dns.domain` allow rules.
- **Private, from sops:**
  - A `sops.templates."pihole-inventory.conf"` (owner `pihole`) renders `dhcp-host=` reservations and
    `host-record=`/`address=` local records.
  - It is loaded via `misc.dnsmasq_lines = ["conf-file=${config.sops.templates."pihole-inventory.conf".path}"]`.
    Only the path is public.
  - `restartUnits = ["pihole-ftl.service"]` on the template, so inventory edits restart FTL.
  - Fallback if FTL rejects `conf-file` in `dnsmasq_lines`: render into `/etc/dnsmasq.d/` and set
    `misc.etc_dnsmasq_d = true`.
- **Web password:** the sops secret is exposed as `FTLCONF_webserver_api_password` through a systemd
  `EnvironmentFile` override on `pihole-ftl`. Verify that the env override works with `readOnly`. Fallback: set
  `webserver.api.pwhash` from a sops-rendered snippet. A public hash is not acceptable.
- **Web UI:** `services.pihole-web` on port 80 at `http://dumont.meine2cent.home/admin`. It is read-only by design: a
  UI change is reverted by the next deploy and refused by `readOnly` anyway.
- **Alternatives:**
  - A Teleporter import from v5. Rejected: one-off imperative state, which is exactly the drift being removed.
  - Putting the reservations in Nix. Rejected: it would publish MACs.

### D8 — Guarded deploy command
- A flake app, `nix run .#deploy-dumont`, a `writeShellApplication`. Everything addresses dumont as
  `yori@192.168.1.2`, never by name.
- **Steps:**
  1. Record dumont's current `/run/current-system`.
  2. `nixos-rebuild test --flake .#dumont --target-host yori@192.168.1.2` with remote sudo. The exact 26.05 flags
     (`--sudo --ask-sudo-password` vs. the older `--use-remote-sudo`) are to be verified.
  3. Health checks from the deploying machine, with retries over ~30 s:
     - `dig @192.168.1.2 example.com` returns an address
     - `dig @192.168.1.2 doubleclick.net` returns `0.0.0.0`
     - `ssh yori@192.168.1.2 true`
     - `systemctl is-active pihole-ftl`
  4. All pass: re-run as `switch`, which builds nothing new and only sets the boot default.
  5. Any check fails: `ssh … sudo <recorded-system>/bin/switch-to-configuration test`, print the failing check, and
     exit 1.
- The boot default only changes after the checks pass, so a power cycle always returns to the last good generation.
- **Alternative:** deploy-rs's magic rollback. It only protects SSH reachability, not DNS health, and adds a tool.
- **Alternative:** plain `nh os switch --target-host`. No guard at all.
- **Implemented (task 6.1, 2026-10-19), deviating from steps 2/4:**
  - The app does not call `nixos-rebuild` twice. dumont's toplevel is a build input of the app, so one evaluation and
    build produce exactly the generation that is tested and later made default. It is copied with
    `nix copy --substitute-on-destination` (26.05's `nixos-rebuild-ng` equivalent: `--use-substitutes`).
  - Activation runs `switch-to-configuration test|boot` in a transient `systemd-run` unit (as `nixos-rebuild-ng` does),
    so a networkd restart that drops SSH does not abort it. "Boot default" is `nix-env -p …/system --set` + `boot`.
  - The sudo password is read once and fed to `sudo -S`. (`nixos-rebuild-ng` 26.05 has `--sudo` and
    `--ask-sudo-password`; `--use-remote-sudo` is gone. It would prompt once per invocation.)
  - The host key is pinned via `UserKnownHostsFile` + `StrictHostKeyChecking=yes`.
  - Copying unsigned paths as `yori` needs `nix.settings.trusted-users = ["@wheel"]` (server hostgroup,
    `remote-deploy.nix`). wheel already has sudo, so this grants nothing new. The first deploy after the install
    lacks it and uses `--build-host` (runbook `dumont-deploy.md`, bootstrap section).

### D9 — Small-disk housekeeping
- `nix.gc` daily with `--delete-older-than 7d` (shared already does this), plus
  `nix.settings.min-free`/`max-free` so GC runs when space is low.
- `boot.loader.systemd-boot.configurationLimit = 5`.
- `documentation.enable = false`.
- `zramSwap.enable = true`.
- journald `SystemMaxUse=200M`.
- Pi-hole query-log retention capped through FTL settings (`database.maxDBdays`).
- Stock `linuxPackages` (LTS) rather than the desktop kernel (CachyOS, now Zen), to stay on the default binary cache.
- **Added during task 3.3 (2026-10-15):** the first build was 2.5 GiB. 809 MiB of that was `linux-firmware` (from
  `enableRedistributableFirmware`) and 197 MiB was the nixpkgs source pinned by the flake registry/NIX_PATH.
  - dumont now ships only `rtl_nic` + `i915` firmware (9.8 MiB). Verify on the hardware with `dmesg` on the
    installer.
  - The server group sets `nixpkgs.flake.setFlakeRegistry/setNixPath = false`.

  Result: **1.5 GiB closure, 693 paths (was 703)**, with no docker, home-manager, X/Wayland, CachyOS, Plymouth,
  Stylix, fonts, pipewire, mesa, GTK/Qt or nix-index. The largest remaining items are kernel modules (144 MiB),
  helix grammars (185 MiB, from the shared CLI tools) and Python (128 MiB, needed by `nixos-rebuild` for local
  rollback). Kernel: linux 6.18 (NixOS default).

### D10 — Boot on the Wyse firmware
- systemd-boot, which also installs the removable fallback `EFI/BOOT/BOOTX64.EFI`. The 3040 firmware is reported to
  boot only that path reliably. Verify on the hardware, and set `efi.canTouchEfiVariables = false` if NVRAM writes
  misbehave.
- The BIOS setup password on ex-fleet units is often Dell's default, which may be needed to enable USB boot. Verify on
  the unit, and record whatever is needed in the install runbook, not in the repo.

- **Resolved during tasks 5.1–5.4 (2026-10-15)**, from FTL 6.7.1's source (`src/config/dnsmasq_config.c`,
  `env.c`) and the 26.05 module:
  - **Keys used:** `dns.upstreams`, `dns.dnssec`, `dns.listeningMode = "LOCAL"`, `dns.domain.{name,local}`,
    `dns.expandHosts`/`domainNeeded`/`bogusPriv`, `dhcp.{active,start,end,router,netmask,leaseTime,ipv6}`,
    `database.maxDBdays`, `misc.{readOnly,dnsmasq_lines}`.
  - **No separate authoritative key:** `dhcp.active = true` writes `dhcp-authoritative` itself.
  - **No RA:** `dhcp.ipv6 = false` writes no `ra-*` range, so no Router Advertisements.
  - **DNS option:** without `dhcp.multiDNS`, dnsmasq hands out its own interface address (`.2`).
  - **`misc.dnsmasq_lines`** is copied verbatim into the generated config, so `conf-file=` works. The
    `/etc/dnsmasq.d` fallback isn't needed.
  - **Inventory:** a plain `sops.secrets.pihole_inventory` (raw dnsmasq lines, owner `pihole`, `restartUnits`) instead
    of a template. There's nothing to interpolate, so a template would add nothing.
  - **Web password:** `FTLCONF_*` env vars are applied at startup. `misc.readOnly` only blocks the API/CLI and
    writing the TOML, so `FTLCONF_webserver_api_password` from a sops-rendered `EnvironmentFile` works.
  - **`file://` lists:** supported by `gravity.sh` 6.4.2.
  - **Known limitation:** the module's `pihole-ftl-setup` only *adds* lists via the API. Removing a list from
    `services.pihole-ftl.lists` leaves it in `gravity.db`, so it has to be deleted in the UI or with `pihole` too.
    Changed URLs count as a removal plus an addition.
  - **Upstreams are a placeholder:** Quad9 (v4 + v6). Compare with wintermute's `PIHOLE_DNS_*` in task 8.1.

### D11 — DHCP redundancy: cold standby on wintermute
- **Decided 2026-10-29.** wintermute's Pi-hole keeps dumont's DHCP settings (range, router, reservations from the
  inventory) with DHCP turned off. If dumont is down and not quickly recoverable, DHCP is turned on there by hand
  (`docs/runbooks/dhcp-failover.md`) and off again once dumont is back. Until the v6 reinstall (task 8.7), the v5
  Pi-hole is the standby: its DHCP has been off since the handover, with settings and reservations still in place.
- **Grace period:** with dumont's 24 h leases, clients that hold a lease try to renew after 12 h and only lose it after
  24 h. An outage hits new devices and reconnecting phones first, so failover can usually wait until someone is at a
  desktop.
- **Standby lease time 1 h.** Clients renew with the server that issued their lease. After failback, a client holding
  a wintermute lease keeps failing to renew until it rebinds by broadcast at 87.5% of the lease. A short standby lease
  brings it back to dumont, and to DNS `.2`, within an hour. dumont answers that rebind because it is authoritative
  (spec: rebind scenario), and dnsmasq pings an address before offering it, which covers dynamic addresses wintermute
  handed out meanwhile.
- **Never two active servers.** Both write `dhcp-authoritative`, so each would NAK the other's leases and clients would
  bounce between them. Turn wintermute off before dumont comes back, or right after if dumont comes back by itself
  (its DHCP is on at boot). A short gap is harmless; an overlap is not.
- **Rejected: a live second server** (split ranges, `dhcp-reply-delay` on wintermute, both non-authoritative). It
  needs the reservations kept in sync on two hosts, slows renewals after reboots without authoritative mode, and
  splits the local names of dynamic clients between two dnsmasq instances. Not worth it for a home LAN.
- **DNS while dumont is down (added 2026-10-29).** dumont hands out `.2` *and* `.3` as DNS servers
  (`dhcp-option=option:dns-server,…` in `misc.dnsmasq_lines`). Otherwise every client with a dumont lease would lose
  DNS with dumont, and a DHCP failover would only fix that as clients renew. Trade-off: clients may also ask `.3`
  while dumont is up. Until the v6 reinstall (task 8.7), wintermute's v5 has its own lists and pre-cutover local
  names, so blocking and local names can differ there, and those queries are missing from dumont's log. The
  Speedport's secondary is already wintermute, so this was accepted.
- **Open:** whether to raise dumont's lease time to 3–7 d for a longer grace period (task 8.10). The range
  `.12–.254` has room for it.

## Risks / Trade-offs

- **v6 regresses something the household relies on.** → Trial run with only reason/deepthought on dumont for a few
  days. wintermute stays untouched until cutover, and rollback is possible until cleanup.
- **A bad inventory line stops FTL, taking all LAN DNS with it.** → The D8 guard reverts automatically. The deploy and
  rollback paths need no DNS.
- **Lost SSH (networkd/firewall mistake).** → The boot default only moves after the checks pass, so a power cycle
  restores the last good generation. A monitor and keyboard are the last resort.
- **Broken bootloader.** → Physical access only, with no BMC. `configurationLimit` keeps the ESP from filling up.
  disko + nixos-anywhere make a full reinstall a single command.
- **eMMC wear or failure.** → Low write load (no swap partition, capped journald and query DB). Recovery is a
  reinstall plus `secrets/dumont.yaml`, since all state is reproducible except history.
- **Single point of failure stays.** dumont down means LAN DNS down, the same as today with wintermute. → Accepted for
  now. Redundancy and monitoring are follow-ups. For DHCP, wintermute is a manual cold standby (D11).
- **Cutover lease staleness.** Clients keep using `.3` as DNS until they renew. → wintermute's DNS keeps running
  through the handover (Migration Plan, phase 3).
- **Queries via the Speedport show the Speedport as the client.** This is an existing trade-off, unchanged.
- **The shared split accidentally changes a desktop.** → The drvPath invariant (D2) is checked before any user
  rebuild.

## Migration Plan

All rebuild, install and deploy commands, as well as live changes on wintermute or the Speedport, are performed by
the user. The assistant prepares the commands and runs only read-only checks.

1. **Phase 0 – repo.**
   - Split `shared` (D2) and verify the drvPath invariant.
   - Add `server` hostgroup, the dumont host, disko, sops (D4), Pi-hole config (D7), the deploy app (D8) and the
     runbooks.
   - Pi-hole on dumont has `dhcp.active = false`.
2. **Phase 1 – install.**
   - nixos-anywhere install (D3).
   - Record dumont's real ULA/GUA prefix addresses in the runbook as `<prefix>::2`, never the MAC.
   - Checks against `@192.168.1.2` and `@<ula>::2`: lookups, blocking, local names from the inventory,
     `dnssec-failed.org` → SERVFAIL with no anchor hack, the web UI loads.
3. **Phase 2 – trial run (a few days).**
   - reason and optionally deepthought use `.2` as DNS via a NetworkManager connection setting. This is not
     committed to the flake.
   - Watch for v6 differences. The rest of the LAN stays on wintermute.
4. **Phase 3 – DHCP and DNS cutover.**
   1. **At least one current lease period beforehand:** shorten wintermute's DHCP lease time to 1 h (DHCP settings →
      Save, which restarts FTL). Read the current lease time and range first, and confirm `.2` is outside the
      dynamic range and not reserved.
   2. Turn off DHCP on wintermute (UI → Save). Its DNS keeps running.
   3. Deploy dumont with `dhcp.active = true`, using the same range and reservations.
   4. Speedport: DNSv4 → `192.168.1.2`, DNSv6 → `<ula-prefix>::2`. Secondary DNSv4/v6 → wintermute's Pi-hole
      (DNS only), replacing Quad9 (decided 2026-10-26).
   5. **Checks:**
      - reconnect a reserved device: reserved IP, DNS `.2`, gateway `.1`
      - `rdisc6` shows only `fe80::1`
      - lookups via `fe80::1` arrive at dumont
      - real client IPs in dumont's query log
   6. ~~Scale wintermute's `pihole-deployment` to 0.~~ Dropped: it stays up with DHCP off as the Speedport's
      secondary DNS until it is reinstalled as v6.
5. **Rollback (any time before phase 4):**
   1. Deploy dumont with `dhcp.active = false`.
   2. Speedport back to `.3` / wintermute's ULA as primary (and drop the secondary or point it at Quad9).
   3. Turn wintermute's DHCP back on, or scale it back to 1 first if it was already at 0.
   4. Restore its lease time.
6. **Phase 4 – cleanup (after ~2 weeks stable):**
   - On wintermute, once the v6 reinstall has replaced the v5 secondary: delete the v5 Pi-hole k3s objects, remove the `.4` secondary address and the `pi.hole` PTR, and remove
     `99-root-ksk-2024.conf`.
   - In the repo: mark `docs/wintermute/pihole/` as historical, and update `docs/hosts.md` (dumont added; wintermute's
     service list without Pi-hole).
   - Fold the root-level Pi-hole handoff into `docs/`, leaving out device MACs.

## Open Questions

These are verified during implementation. None of them changes the approach.

- The exact v6 `pihole.toml` keys for authoritative DHCP, RA off, the interface and listening mode.
- Whether `conf-file=` in `misc.dnsmasq_lines` is accepted, or the `/etc/dnsmasq.d` fallback is needed.
- Whether `FTLCONF_webserver_api_password` overrides work with `misc.readOnly = true`.
- Whether v6 accepts `file://` URLs in `services.pihole-ftl.lists`.
- wintermute's current DHCP lease time and range (read before phase 3).
- The remote-sudo flags of `nixos-rebuild` in 26.05.
- The Wyse 3040 firmware: whether USB boot needs the setup password, and whether the EFI fallback path alone boots.
- FTL restart time on the Atom, to size the health-check retry window.

## Follow-ups

Out of scope here and recorded for later pickup. Each one also goes into the docs (task 8.x), so it survives this
change being archived.

- **Pi-hole monitoring from wintermute.** The checks were already designed and verified, run every ~2 min:
  - `dig @192.168.1.2 example.com` returns an address
  - `dig @192.168.1.2 doubleclick.net` returns `0.0.0.0`
  - `dig @192.168.1.1 doubleclick.net` returns `0.0.0.0`, which catches the Speedport no longer forwarding

  Alert once per change of state. Running on wintermute, the checks now watch a *different* host, so "dumont is down"
  can be reported. Open questions carried over:
  - **Alert channel:** ntfy, e-mail (but the mail server on neuromancer is being retired), or a Telegram/Signal bot.
    It must not depend on the LAN's DNS.
  - **Platform:** a k3s CronJob now, or a systemd timer once wintermute is on NixOS.
  - **External dead-man's switch:** whether to add one (healthchecks.io-style).
  - **Extra checks:** whether to also check DHCP (`:67` listening) and gravity freshness.
- **Secondary DNS for redundancy.** Once wintermute is on NixOS, a DNS-only Pi-hole there from the same module, fed
  the same lists and the sops inventory (local records, plus DHCP configured but off as the D11 standby). DHCP hands out both servers
  (done 2026-10-29, D11), and the
  Speedport would get a secondary DNSv4/v6 if its UI allows. **Partly done 2026-10-26:** the Speedport's secondary
  is already wintermute's v5 Pi-hole (DNS only, DHCP off), replacing Quad9. It lacks the dumont inventory (local names
  only resolve if wintermute has them) and the same lists; the v6 reinstall (task 8.7) closes that gap.
- **Deploying from wintermute.** It needs only the flake checkout plus the shared key once wintermute runs NixOS. The
  deploy app already addresses dumont by IP.
- **HTTPS for the web UI.** v6 can serve TLS on :443 with its own cert. Consider it if the UI is ever reached from
  outside the LAN, or once a LAN CA exists.
- **Unattended updates.** Deliberately none. dumont changes only through guarded deploys from a desktop. Revisit if
  security updates lag because the desktops are often off.
- **Pi-hole v6 web password rotation.** Covered by editing `secrets/dumont.yaml` and redeploying. Revisit if it ever
  needs a UI-driven flow.
