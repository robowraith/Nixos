# The Project - GitHub Copilot Context

This is the NixOS configuration of a machine running NixOS unstable
and using Home Manager to manage user applications and configuration.

## Structure

This is a **multi-machine, multi-user** NixOS configuration. System configurations
are under `hosts/`, user configurations under `users/`, with reusable components
in `lib/`, `modules/`, and `profiles/`. All is tied together in a Flake at `./flake.nix`.

### Directory Layout
```
.
├── lib/                    # Builder functions
│   ├── default.nix        # Main lib export
│   ├── hosts.nix          # mkHost function
│   └── users.nix          # mkUser function
├── hosts/                 # System configurations
│   ├── <hostname>/       # Machine-specific
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   └── shared/           # Common system config
│       └── default.nix
├── users/                # User configurations
│   ├── <username>/      # User-specific
│   │   ├── default.nix
│   │   └── <hostname>.nix  # Host-specific overrides (optional)
│   └── shared/          # Shared programs
│       ├── home.nix
│       └── programs/
├── modules/             # Feature modules (e.g., nvidia.nix)
├── profiles/            # Setup profiles (e.g., desktop.nix)
├── secrets/             # Per-host secrets (<hostname>.yaml)
└── system/              # Legacy (being phased out)
```

### Key Directories

**`lib/`** - Helper functions for building configurations
- `hosts.nix` - `mkHost` function for creating NixOS configurations
- `users.nix` - `mkUser` function for creating Home Manager configurations

**`hosts/`** - Per-machine system configurations
- Each subdirectory represents a physical/virtual machine
- `default.nix` contains machine-specific settings
- `hardware-configuration.nix` is auto-generated (don't modify directly)
- `shared/` contains common configuration for all machines

**`users/`** - Per-user configurations
- Each subdirectory represents a user
- `default.nix` contains user-specific settings (git identity, packages, etc.)
- Optional `<hostname>.nix` for host-specific user overrides
- `shared/programs/` contains program configurations used by all users

**`modules/`** - Reusable feature modules (e.g., NVIDIA, gaming)

**`profiles/`** - Common setup bundles (e.g., desktop, development, server)

**`secrets/`** - Per-host encrypted secret files using sops-nix

### Program Configuration
Programs are configured under `users/shared/programs/`:
- Each program has its own folder (e.g., `helix/`, `fish/`, `git/`)
- Configuration files typically named `<program>.nix`
- Complex programs can have multiple files (e.g., `fish/` contains aliases.nix, functions.nix, etc.)
- Auto-installation: If folder name matches nixpkgs package name, it's installed automatically

Example: The configuration for Helix is in `users/shared/programs/helix/helix.nix`.

## Remote System Access

The NixOS system being configured (hostname "reason") is a **remote machine** accessible via SSH:
- **SSH Connection**: `ssh privat_reason`
- **All Commands**: Execute all terminal commands (nixos-rebuild, home-manager, etc.) via SSH
- **File Editing**: Edit files locally in the workspace, deploy changes remotely

### Running Commands on the Remote System

Always prefix commands with `ssh privat_reason` when they need to execute on the target system:

```bash
# System rebuild (remote)
ssh privat_reason "sudo nixos-rebuild switch --flake .#reason"
ssh privat_reason "sudo nixos-rebuild test --flake .#reason"

# Home Manager (remote)
ssh privat_reason "home-manager switch --flake .#joachim@reason"

# Checking system state (remote)
ssh privat_reason "nixos-rebuild list-generations"
ssh privat_reason "journalctl -xe"

# Local operations (no SSH needed)
nix flake check
nix fmt
git status
```

## Best Practices

### General Guidelines
1. **Modularity**: Keep configurations in logical, focused modules (single responsibility)
2. **No Hardcoding**: Use variables and config references instead of hardcoded paths
   - Use `config.home.homeDirectory` instead of `/home/username`
   - Use `config.users.users.<name>.uid` instead of hardcoded UIDs
3. **Documentation**: Add comments for non-obvious configurations and complex logic
4. **State Version**: Keep `system.stateVersion` and `home.stateVersion` in sync (currently 25.05)
5. **Git Tracking**: All files must be tracked in git for flakes to work properly
6. **Immutability**: Prefer declarative over imperative configurations
7. **Remote Execution**: Always run deployment and system commands via `ssh privat_reason`

### System Configuration
1. **Hardware Specific**: Keep hardware settings in `hardware-configuration.nix`, regenerate when hardware changes
2. **Module Imports**: Use `imports = [ ]` for modular organization
3. **Security First**: 
   - Disable unnecessary services by default
   - Use SSH keys only, disable password authentication
   - Configure firewall explicitly (deny by default, allow specific ports)
   - Use sops-nix for all credentials
4. **Performance**: 
   - Enable binary caches for faster builds (e.g., Chaotic Nyx for CachyOS kernel)
   - Configure garbage collection to prevent disk bloat
   - Use `--cores 0` for parallel builds
5. **Secrets**: Use sops-nix, never commit plain-text credentials
6. **Services**: Configure services in their logical modules, not in main config
7. **Environment**: Use `environment.sessionVariables` sparingly; prefer program-specific configs

### Home Manager
1. **Program Modules**: Use `programs.<name>` when available instead of manual config files
2. **Declarative**: Prefer Home Manager options over imperative setup scripts
3. **Auto-discovery**: Name program folders to match package names for auto-installation
4. **Variables**: 
   - Use `config.home.homeDirectory` instead of hardcoded `/home/username`
   - Use `${pkgs.package}` for package paths
5. **Activation Scripts**: Avoid `home.activation` when possible; use proper module options
6. **File Management**: Use `home.file` or `xdg.configFile` for dotfiles
7. **Layering**: System-level in NixOS config, user-level in Home Manager

### Flake Management
1. **Lock File**: Always commit `flake.lock` for reproducibility
2. **Input Following**: Use `inputs.nixpkgs.follows = "nixpkgs"` for consistency across inputs
3. **Dev Tools**: Provide `devShells` for development environment with necessary tools
4. **Formatter**: Define formatter for `nix fmt` (e.g., `nixpkgs-fmt`)
5. **Clear Outputs**: Organize outputs logically:
   - `nixosConfigurations.<hostname>` for systems
   - `homeConfigurations.<username>@<hostname>` for users (note the `@hostname` suffix)
   - `devShells.<system>.default` for development
   - `formatter.<system>` for code formatting
6. **System Variable**: Use a `system` variable to avoid repeating `"x86_64-linux"`
7. **Descriptions**: Provide clear description in flake metadata
8. **Multi-Machine**: Define hosts and users centrally in `flake.nix` using `mkHost` and `mkUser`
9. **Builder Functions**: Use helper functions from `lib/` for consistency across configurations

### Secrets Management (sops-nix)
1. **Age Keys**: 
   - Backup age keys securely (encrypted USB, password manager, separate machine)
   - Store at `/var/lib/sops/age/keys.txt` on NixOS
   - Each machine needs its own age key
   - Document recovery procedures
2. **Permissions**: Set appropriate permissions on secret files (mode = "0600")
3. **Templates**: Use `sops.templates` for files requiring multiple secrets
4. **Key Rotation**: Document and practice key rotation procedures
5. **Never Commit**: Encrypted secrets are safe to commit, but never plain-text
6. **Scoping**: Per-host secrets in `secrets/<hostname>.yaml`, configure in host's config
7. **Placeholders**: Use `config.sops.placeholder.<secret>` in templates
8. **Per-Host**: Each machine has its own secret file (e.g., `secrets/reason.yaml`)
9. **`.sops.yaml`**: Define encryption rules per host using path_regex and age public keys

### Code Quality
1. **Formatting**: Run `nix fmt` before committing
2. **Validation**: Use `nix flake check` to verify configuration
3. **Testing**: Use `nixos-rebuild test` or `build` before `switch`
4. **Comments**: Explain complex logic, non-obvious choices, and workarounds
5. **Consistency**: Follow existing patterns in the codebase
6. **DRY**: Use functions and `lib` utilities to avoid repetition (e.g., `lib.genAttrs`, `map`)
7. **Lint**: Consider using `statix` for additional linting

### NixOS-Specific Patterns
1. **Helper Functions**: Create helper functions for repetitive patterns
   ```nix
   let
     mkMount = name: { device = "//server/${name}"; fsType = "cifs"; };
   in
   ```
2. **Attribute Sets**: Use `lib.genAttrs` for generating similar configurations
3. **Overrides**: Use `override` and `overrideAttrs` for package customization
4. **Overlays**: Create overlays for custom packages or modifications
5. **Options**: Define custom options with `lib.mkOption` when building reusable modules
6. **Assertions**: Use `assertions` to validate configuration
7. **Conditionals**: Use `lib.mkIf` for conditional configuration

### Maintenance
1. **Updates**: 
   - Regularly update flake inputs (`nix flake update`)
   - Test updates before deploying
   - Review changelogs for breaking changes
2. **Garbage Collection**: 
   - Enable automatic cleanup (`nix.gc.automatic = true`)
   - Keep sufficient generations for rollback (30 days recommended)
3. **Generations**: 
   - Keep recent generations for easy rollback
   - Delete old generations to free space
   - List with `nixos-rebuild list-generations`
4. **Documentation**: 
   - Update README when adding major features
   - Document custom modules and functions
   - Keep troubleshooting section current
5. **Backups**: 
   - Backup entire configuration repository
   - Backup age keys separately and securely
   - Test restoration procedures
6. **Monitoring**: Watch for deprecation warnings during builds
7. **Optimization**: Periodically run `nix-store --optimise`

### Common Patterns in This Configuration

1. **Multi-Machine**: Centralized host/user definitions in `flake.nix` using builder functions
2. **Module Structure**: Feature modules in `modules/`, system config in `hosts/`, user config in `users/`
3. **Program Auto-loading**: Directory names under `users/shared/programs/` auto-discovered
4. **Secrets**: Per-host SOPS files in `secrets/<hostname>.yaml` with age encryption
5. **Builder Functions**: `lib.mkHost` and `lib.mkUser` for consistent configuration building
6. **Profiles**: Reusable configuration bundles in `profiles/` (desktop, development, etc.)
7. **Development**: `nix develop` provides tools for working with config
8. **Formatting**: Use `nix fmt` for consistent code style
9. **Deployment**: Use `.#<hostname>` for systems, `.#<username>@<hostname>` for users

### When Making Changes

1. **Test First**: Always test with `nixos-rebuild test` or `build`
2. **Incremental**: Make small, focused changes
3. **Validate**: Run `nix flake check` after changes
4. **Format**: Run `nix fmt` before committing
5. **Review**: Check diffs before applying
6. **Rollback Plan**: Know how to rollback if something breaks
7. **Documentation**: Update relevant docs if changing structure

### Multi-Machine Management

**Adding a New Machine:**
1. Create `hosts/<hostname>/` directory
2. Generate hardware config: `nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix`
3. Create `hosts/<hostname>/default.nix` with machine-specific settings
4. Generate age key: `sudo age-keygen -o /var/lib/sops/age/keys.txt`
5. Get public key: `sudo age-keygen -y /var/lib/sops/age/keys.txt`
6. Update `.sops.yaml` with new host's age public key
7. Create `secrets/<hostname>.yaml` for host-specific secrets
8. Add to `flake.nix` in the `hosts` attribute set
9. Deploy: `sudo nixos-rebuild switch --flake .#<hostname>`

**Adding a New User:**
1. Create `users/<username>/` directory
2. Create `users/<username>/default.nix` with user settings
3. Add to `flake.nix` in the `users` attribute set with target hosts
4. Add system user in appropriate host config(s)
5. Deploy: `home-manager switch --flake .#<username>@<hostname>`

**Deployment Commands:**
```bash
# System configuration (remote execution required)
ssh privat_reason "sudo nixos-rebuild switch --flake .#<hostname>"
ssh privat_reason "sudo nixos-rebuild test --flake .#<hostname>"      # Test without activation
ssh privat_reason "sudo nixos-rebuild build --flake .#<hostname>"     # Build without activation

# User configuration (remote execution required, note the @hostname suffix)
ssh privat_reason "home-manager switch --flake .#<username>@<hostname>"

# Example for current system
ssh privat_reason "sudo nixos-rebuild switch --flake .#reason"
ssh privat_reason "home-manager switch --flake .#joachim@reason"

# Local validation (no SSH needed)
nix flake check
nix fmt
```

### Troubleshooting

1. **Build Errors**: Check syntax with `nix flake check`
2. **Import Errors**: Ensure all files are tracked in git
3. **Secrets**: Verify age key exists and `.sops.yaml` is correct
4. **Network**: Check interface names match actual hardware
5. **Rollback**: Boot menu or `nixos-rebuild switch --rollback`
6. **Logs**: Use `journalctl` for system service logs
7. **Evaluation**: Add `--show-trace` for detailed error traces
8. **Multi-Machine**: Verify host is defined in `flake.nix` and has correct modules
9. **User Config**: Ensure user is listed for the target host in `flake.nix`
