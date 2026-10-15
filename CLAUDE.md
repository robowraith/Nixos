# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Formatting
```bash
nix fmt          # Format all Nix files with alejandra
alejandra .      # Alternative direct invocation
```

### Linting
```bash
statix check .   # Check for anti-patterns
statix fix .     # Auto-fix issues
deadnix .        # Find unused variable bindings
deadnix -e .     # Auto-remove unused bindings
```

### Validation
```bash
nix flake check  # Validate the full flake configuration
```

### Pre-commit hooks
```bash
nix develop            # Enter dev shell (installs hooks automatically)
pre-commit run --all-files  # Run all hooks manually
```

### Deployment (run from the flake directory)

**Rebuilds are the user's job.** Every rebuild command below needs sudo and an
interactive password prompt, so Claude must never run one — not `nh os switch`,
not `nixos-rebuild`, not any variant. Print the command the user should run and
stop there. Claude may still run read-only checks itself: `nix flake check`,
`nix eval`, `nix build` of a config's `toplevel`, `nix fmt`, `statix`, `deadnix`.

```bash
# System rebuild - preferred tool is `nh`. Select the host with -H, not `.#host`
nh os switch .                   # Switch, using the local hostname
nh os switch . -H deepthought    # Switch to new system config (deepthought)
nh os switch . -H reason         # Switch to new system config (reason)
nh os test . -H deepthought      # Test without making default

# Or with nixos-rebuild directly
sudo nixos-rebuild switch --flake .#deepthought
sudo nixos-rebuild test --flake .#deepthought
```

Home Manager is integrated into the NixOS config via `home-manager.nixosModules.home-manager`,
so a system rebuild also applies the user config. There are no standalone `homeConfigurations`
outputs: `nh home switch` and `home-manager switch --flake` do NOT work in this repo.

### Secrets
```bash
sops secrets/shared.yaml           # Edit shared secrets
sops secrets/<hostname>.yaml       # Edit host-specific secrets
ssh-to-age -i ~/.ssh/id_ed25519    # Convert SSH key to age key
```

### Updating Inputs
```bash
nix flake update                      # Update all flake inputs
nix flake update nixpkgs              # Update a single input
nix flake update nixpkgs-unstable     # Bump only the `pkgs.unstable.*` packages
```

## Architecture

### Cascading Configuration Hierarchy

**System (NixOS):** `system/shared` -> `system/hostgroups/<group>` -> `system/hosts/<hostname>`

**User (Home Manager):** `dotfiles/shared` -> `dotfiles/usergroups/<group>` -> `dotfiles/users/<username>`

Each level's `default.nix` auto-discovers and imports all `.nix` files in its `modules/` subdirectory. The `programs/` subdirectory uses a recursive collector that skips `_uninstalled/` directories.

### Flake Structure

`flake.nix` defines a `mkHost` function that wires together:
- `system/hosts/<hostname>` + `system/shared` for NixOS config
- `dotfiles/users/<username>` for Home Manager config (via `home-manager.nixosModules`), unless the host
  passes `homeManager = false` (headless hosts get no Home Manager at all)
- All external modules: `sops-nix`, `stylix`, `nix-index-database`, `home-manager`, `vicinae`
- `stateVersion` is per host (`mkHost` default `"25.11"`); new hosts pass their install release

Active hosts: `reason` (user: `joachim`, desktop), `deepthought` (user: `jhoss`, work laptop), `dumont` (user: `yori`, headless Pi-hole appliance, Dell Wyse 3040; no Home Manager, per-host sops key, deployed remotely from a desktop).

`specialArgs`/`extraSpecialArgs` pass `{inputs, hostname, username, platform, stateVersion}` through all layers.

### Key Conventions

- **`_uninstalled/`**: Programs kept in git but not currently active. Place program folders here to disable without losing config.
- **Auto-discovery**: Host `default.nix` files use `builtins.readDir` to import all `.nix` files in `./modules/` automatically — no manual import list needed.
- **Secrets**: SOPS with age encryption. Rules defined in `.sops.yaml`. Per-host secrets go in `secrets/<hostname>.yaml`.
  Desktops decrypt `secrets/shared.yaml` with the shared age key. A host that sets `fleet.sops.perHostKey = true`
  instead decrypts only `secrets/<hostname>.yaml` with an age identity derived from its SSH host key, and must never
  receive the shared key.
- **Shared vs. hostgroups**: `system/shared` holds only what every machine needs (nix settings/GC, sops, ssh, users,
  locale, base CLI tools, firewall). Anything graphical or desktop-only (Docker, the desktop kernel (currently Zen) + scx, Plymouth,
  Stylix, fonts, dconf, desktop user groups, the KeePassXC/KeeShare sops template) lives in `system/hostgroups/desktop`. Don't add desktop settings to
  `shared`: they would land on servers.
- **Hostgroups**: `system/hostgroups/` groups machines by shared traits (e.g., `desktop`, `home`, `mine`, `server`). `server` is the headless counterpart of `desktop`: systemd-networkd, no docs or nix-index, zram, small-disk GC/journald limits, no flake registry pin. Servers must not import `home` (NetworkManager + CIFS mounts). A host opts in by importing the group in its `default.nix`.
- **Usergroups**: `dotfiles/usergroups/` groups users similarly (currently `joachims` for both `joachim` and `jhoss`).
- **Overlays**: Defined inline in `flake.nix` (currently: `unstable` namespace, herbstluftwm patch, freac codec fix).
- **Theming**: Stylix handles system-wide theming for both NixOS and Home Manager.
- **Flake inputs**: `nixpkgs` tracks `nixos-26.05`. A second input, `nixpkgs-unstable`, tracks `nixos-unstable` and is exposed via overlay as `pkgs.unstable.<package>` (allowUnfree enabled) for packages that need to be newer than the release channel. Do NOT add `inputs.nixpkgs.follows` to `vicinae` (breaks Cachix cache).
- **Git tracking**: All files must be tracked in git for flakes to evaluate correctly. Run `git add` on new files before rebuilding.
- **No hardcoding**: Use `config.home.homeDirectory` instead of `/home/username`, and `${pkgs.package}` for package store paths.
- **hardware-configuration.nix**: Auto-generated by NixOS — do not edit manually; regenerate with `nixos-generate-config` if hardware changes.
- **Home Manager file management**: Use `home.file` or `xdg.configFile` for dotfiles. Avoid `home.activation` scripts; prefer declarative module options.
- **Conditionals**: Use `lib.mkIf` for conditional config, `lib.genAttrs` for generating repeated attribute sets.
- **SOPS templates**: Use `sops.templates` when a file needs multiple secrets interpolated; reference secrets via `config.sops.placeholder.<name>`. Age keys are stored at `/var/lib/sops/age/keys.txt` on each NixOS host.

### Adding a New Host
1. Create `system/hosts/<hostname>/default.nix` importing `../../shared` and desired hostgroups
2. Add `system/hosts/<hostname>/hardware-configuration.nix`
3. Add age key to `.sops.yaml`, create `secrets/<hostname>.yaml`
4. Register in `flake.nix` via `mkHost`

### Adding a New User
1. Create `dotfiles/users/<username>/default.nix` importing `../../shared`, desired usergroups, `./modules`, `./programs`
2. Register in `flake.nix` via the `home-manager.users` attribute inside the relevant `mkHost` call

### Adding a Program
- **All users**: `dotfiles/shared/programs/<program>/<program>.nix`
- **Usergroup**: `dotfiles/usergroups/<group>/programs/<program>/<program>.nix`
- **Single user**: `dotfiles/users/<username>/programs/<program>/<program>.nix`

No manual import registration needed — the `default.nix` collector picks up `.nix` files automatically.

## Troubleshooting

- **Build errors**: Run `nix flake check` first; add `--show-trace` to any Nix command for a full evaluation trace.
- **Import errors**: Check that new files are tracked with `git add`.
- **Secrets**: Verify age key exists at `/var/lib/sops/age/keys.txt` (per-host-key hosts: `/etc/ssh/ssh_host_ed25519_key`) and that `.sops.yaml` includes the host's public key.
- **Rollback**: Use the boot menu, or `sudo nixos-rebuild switch --rollback`.
- **Logs**: `journalctl -xe` for service failures.
