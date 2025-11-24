# The Project - GitHub Copilot Context

This is the NixOS configuration of a machine running NixOS unstable
and using Home Manager to manage user applications and configuration.

# IMPORTANT: The configuration is deployed on another system. You can reach it via `ssh privat_reason`. The configuration path is `/home/joachim/nixos`.

## Structure

The system configuration is under `system/`, the Home Manager configuration
under `dotfiles/`. All is tied together in a Flake at `./flake.nix`.

The base configuration files (`home.nix` and `configuration.nix`) should contain
only general configuration options. Specific options shall be organized in
their own subfolders and files.

### System Configuration (`system/`)
- `configuration.nix` - Main system config (imports modules, packages, services)
- `hardware-configuration.nix` - Auto-generated hardware settings (don't modify directly)
- `modules/` - Modular system components:
  - `boot.nix` - Bootloader, kernel, Plymouth boot splash
  - `networking.nix` - Network settings, static IP, firewall rules
  - `nvidia.nix` - GPU configuration, Wayland environment variables
  - `filesystems.nix` - CIFS network mounts, filesystem definitions
  - `users.nix` - User and group management
  - `localization.nix` - Timezone, locale, keyboard layout
- `sops/` - Secrets management configuration

### Home Manager Configuration (`dotfiles/`)
- `home.nix` - Main Home Manager config (auto-imports from programs/)
- `programs/` - Per-program configurations in subdirectories
  - Each program has its own folder (e.g., `helix/`, `fish/`, `git/`)
  - Configuration files typically named `<program>.nix`
  - Complex programs can have multiple files (e.g., `fish/` contains aliases.nix, functions.nix, etc.)
  - Auto-installation: If folder name matches nixpkgs package name, it's installed automatically

Example: The configuration for Helix is in `dotfiles/programs/helix/helix.nix`.

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
   - `homeConfigurations.<username>` for users
   - `devShells.<system>.default` for development
   - `formatter.<system>` for code formatting
6. **System Variable**: Use a `system` variable to avoid repeating `"x86_64-linux"`
7. **Descriptions**: Provide clear description in flake metadata

### Secrets Management (sops-nix)
1. **Age Keys**: 
   - Backup age keys securely (encrypted USB, password manager, separate machine)
   - Store at `/var/lib/sops/age/keys.txt` on NixOS
   - Document recovery procedures
2. **Permissions**: Set appropriate permissions on secret files (mode = "0600")
3. **Templates**: Use `sops.templates` for files requiring multiple secrets
4. **Key Rotation**: Document and practice key rotation procedures
5. **Never Commit**: Encrypted secrets are safe to commit, but never plain-text
6. **Scoping**: System secrets in `system/sops/`, user secrets in home-manager sops config
7. **Placeholders**: Use `config.sops.placeholder.<secret>` in templates

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

1. **Module Structure**: Each system component in its own file under `system/modules/`
2. **CIFS Mounts**: Helper function `mkCifsMount` with `lib.genAttrs`
3. **Program Auto-loading**: Directory names under `dotfiles/programs/` auto-discovered
4. **Secrets**: SOPS with age encryption, templates for multi-secret files
5. **Development**: `nix develop` provides tools for working with config
6. **Formatting**: Use `nix fmt` for consistent code style
7. **Cache**: Chaotic Nyx binary cache for CachyOS kernel packages

### When Making Changes

1. **Test First**: Always test with `nixos-rebuild test` or `build`
2. **Incremental**: Make small, focused changes
3. **Validate**: Run `nix flake check` after changes
4. **Format**: Run `nix fmt` before committing
5. **Review**: Check diffs before applying
6. **Rollback Plan**: Know how to rollback if something breaks
7. **Documentation**: Update relevant docs if changing structure

### Troubleshooting

1. **Build Errors**: Check syntax with `nix flake check`
2. **Import Errors**: Ensure all files are tracked in git
3. **Secrets**: Verify age key exists and `.sops.yaml` is correct
4. **Network**: Check interface names match actual hardware
5. **Rollback**: Boot menu or `nixos-rebuild switch --rollback`
6. **Logs**: Use `journalctl` for system service logs
7. **Evaluation**: Add `--show-trace` for detailed error traces
