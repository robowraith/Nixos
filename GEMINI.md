# The project

This is the NixOS configuration of a machine running NixOS unstable
and using Home Manager to manage user applications and configuration.

## Structure

This is a **multi-machine, multi-user** NixOS configuration. System configurations
are under `hosts/`, user configurations under `users/`, with reusable components
in `lib/`, `modules/`, and `profiles/`. All is tied together in a Flake at `./flake.nix`.

### Directory Layout
- `lib/` - Helper functions for building hosts and users
  - `hosts.nix` - `mkHost` function for system configurations
  - `users.nix` - `mkUser` function for home-manager configurations
- `hosts/` - System configurations (per-machine)
  - `<hostname>/` - Machine-specific configuration
    - `default.nix` - Main machine config
    - `hardware-configuration.nix` - Hardware-specific settings
  - `shared/` - Common system configuration shared across machines
- `users/` - User configurations
  - `<username>/` - User-specific configuration
    - `default.nix` - User settings (git identity, packages, etc.)
    - `<hostname>.nix` - Host-specific user overrides (optional)
  - `shared/` - Shared user configuration and programs
    - `programs/` - Per-program configurations
- `modules/` - Reusable feature modules (e.g., `nvidia.nix`)
- `profiles/` - Common setup profiles (e.g., `desktop.nix`, `development.nix`)
- `secrets/` - Per-host encrypted secrets (e.g., `reason.yaml`)
- `system/` - Legacy system configuration (being phased out)

### Program Configuration
Programs are configured under `users/shared/programs/`:
- Each program has its own folder (e.g., `helix/`, `fish/`, `git/`)
- Configuration files named `<program>.nix`
- Complex programs can have multiple files (e.g., `fish/` has aliases, functions, etc.)
- Auto-installation: If folder name matches nixpkgs package name, it's installed automatically

Example: The configuration for Helix is in `users/shared/programs/helix/helix.nix`.

## Best Practices

### General Guidelines
1. **Modularity**: Keep configurations in logical, focused modules
2. **No Hardcoding**: Use variables and config references instead of hardcoded paths
3. **Documentation**: Add comments for non-obvious configurations
4. **State Version**: Keep `system.stateVersion` and `home.stateVersion` in sync
5. **Git Tracking**: All files must be tracked in git for flakes to work

### System Configuration
1. **Hardware Specific**: Keep hardware settings in `hardware-configuration.nix`
2. **Module Imports**: Use `imports = [ ]` for modular organization
3. **Security First**: 
   - Disable unnecessary services
   - Use SSH keys, not passwords
   - Configure firewall explicitly
4. **Performance**: Enable binary caches for faster builds
5. **Secrets**: Use sops-nix, never commit plain-text credentials

### Home Manager
1. **Program Modules**: Use `programs.<name>` when available instead of manual config
2. **Declarative**: Prefer Home Manager options over imperative setup
3. **Auto-discovery**: Name program folders to match package names for auto-installation
4. **Variables**: Use `config.home.homeDirectory` instead of hardcoded paths
5. **Activation Scripts**: Avoid when possible; use proper module options

### Flake Management
1. **Lock File**: Commit `flake.lock` for reproducibility
2. **Input Following**: Use `inputs.nixpkgs.follows` for consistency
3. **Dev Tools**: Provide `devShells` for development environment
4. **Formatter**: Define formatter for `nix fmt`
5. **Clear Outputs**: Organize outputs logically:
   - `nixosConfigurations.<hostname>` for systems
   - `homeConfigurations.<username>@<hostname>` for users (note the `@hostname` suffix)
   - `devShells.<system>.default` for development
   - `formatter.<system>` for code formatting
6. **Multi-Machine**: Define hosts and users centrally in `flake.nix`
7. **Builder Functions**: Use `lib.mkHost` and `lib.mkUser` for consistency

### Secrets (sops-nix)
1. **Age Keys**: Backup age keys securely (encrypted USB, password manager)
2. **Permissions**: Set appropriate permissions on secret files (0600)
3. **Templates**: Use templates for files requiring multiple secrets
4. **Key Rotation**: Document and practice key rotation procedures
5. **Never Commit**: Use `.gitignore` for unencrypted secret files

### Code Quality
1. **Formatting**: Run `nix fmt` before committing
2. **Validation**: Use `nix flake check` to verify configuration
3. **Testing**: Use `nixos-rebuild test` before `switch`
4. **Comments**: Explain complex logic and non-obvious choices
5. **Consistency**: Follow existing patterns in the codebase

### Maintenance
1. **Updates**: Regularly update flake inputs (`nix flake update`)
2. **Garbage Collection**: Enable automatic cleanup
3. **Generations**: Keep recent generations for easy rollback
4. **Documentation**: Update README when adding major features
5. **Backups**: Backup configuration and age keys regularly

## Deployment

### System Configuration
```bash
# Deploy to current machine
sudo nixos-rebuild switch --flake .#<hostname>

# Test before switching
sudo nixos-rebuild test --flake .#<hostname>

# Build without activating
sudo nixos-rebuild build --flake .#<hostname>
```

### User Configuration
```bash
# Deploy home-manager (note the @hostname suffix)
home-manager switch --flake .#<username>@<hostname>

# Example for user joachim on machine reason
home-manager switch --flake .#joachim@reason
```

## Adding New Machines

1. **Create host directory**: `mkdir -p hosts/<hostname>`
2. **Generate hardware config**: `nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix`
3. **Create `hosts/<hostname>/default.nix`** with machine-specific settings
4. **Generate age key**: `sudo age-keygen -o /var/lib/sops/age/keys.txt`
5. **Update `.sops.yaml`** with new host's age public key
6. **Create `secrets/<hostname>.yaml`** for host-specific secrets
7. **Add to `flake.nix`** in the `hosts` attribute set
8. **Deploy**: `sudo nixos-rebuild switch --flake .#<hostname>`

## Adding New Users

1. **Create user directory**: `mkdir -p users/<username>`
2. **Create `users/<username>/default.nix`** with user settings
3. **Add to `flake.nix`** in the `users` attribute set with target hosts
4. **Add system user** in appropriate host config
5. **Deploy**: `home-manager switch --flake .#<username>@<hostname>`

