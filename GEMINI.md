# The project

This is the NixOS configuration of a machine running NixOS unstable
and using Home Manager to manage user applications and configuration.

## Structure

The system configuration is under `system/`, the Home Manager configuration
under `dotfiles/`. All is tied together in a Flake at `./flake.nix`.

The base configuration files (`home.nix` and `configuration.nix`) should contain
only general configuration options. Specific options shall be organized in
their own subfolders and files.

### System Configuration (`system/`)
- `configuration.nix` - Main system config (imports modules, packages, services)
- `hardware-configuration.nix` - Auto-generated hardware settings
- `modules/` - Modular system components:
  - `boot.nix` - Bootloader, kernel, Plymouth
  - `networking.nix` - Network settings, firewall
  - `nvidia.nix` - GPU configuration, Wayland environment
  - `filesystems.nix` - CIFS mounts, filesystem definitions
  - `users.nix` - User and group management
  - `localization.nix` - Timezone, locale, keyboard layout
- `sops/` - Secrets management configuration

### Home Manager Configuration (`dotfiles/`)
- `home.nix` - Main Home Manager config (auto-imports from programs/)
- `programs/` - Per-program configurations in subdirectories
  - Each program has its own folder (e.g., `helix/`, `fish/`, `git/`)
  - Configuration files named `<program>.nix`
  - Complex programs can have multiple files (e.g., `fish/` has aliases, functions, etc.)

Example: The configuration for Helix is in `dotfiles/programs/helix/helix.nix`.

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
5. **Clear Outputs**: Organize outputs logically (nixosConfigurations, homeConfigurations, etc.)

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

