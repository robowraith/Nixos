# Migration Guide: Multi-Machine Configuration

## ✅ What Was Done

The configuration has been successfully restructured for multi-machine and multi-user support!

### Changes Summary

**62 files changed** with a complete restructuring:

1. **New Directory Structure Created:**
   - `lib/` - Helper functions for building hosts and users
   - `hosts/reason/` - Current machine configuration
   - `hosts/shared/` - Shared system configuration
   - `users/joachim/` - User-specific configuration
   - `users/shared/` - Shared user/program configurations
   - `modules/` - Reusable feature modules
   - `profiles/` - Common setup profiles
   - `secrets/` - Per-host secret files

2. **Configuration Files Migrated:**
   - System config → `hosts/reason/` and `hosts/shared/`
   - User programs → `users/shared/programs/`
   - Secrets → `secrets/reason.yaml`
   - Hardware config → `hosts/reason/hardware-configuration.nix`

3. **Flake Updated:**
   - New multi-host builder system
   - User@host combination support
   - Centralized host and user definitions

## 🚀 How to Use

### Deploy System Configuration

```bash
# Current machine (reason)
sudo nixos-rebuild switch --flake .#reason

# Future machines (example)
sudo nixos-rebuild switch --flake .#laptop
```

### Deploy User Configuration

```bash
# Current user on current machine
home-manager switch --flake .#joachim@reason

# Same user on different machine (future)
home-manager switch --flake .#joachim@laptop
```

### Development

```bash
# Enter development shell
nix develop

# Format code
nix fmt

# Check configuration
nix flake check
```

## 📝 Adding New Machines

1. **Create host directory:**
   ```bash
   mkdir -p hosts/laptop
   ```

2. **Generate hardware config:**
   ```bash
   nixos-generate-config --show-hardware-config > hosts/laptop/hardware-configuration.nix
   ```

3. **Create host config:**
   ```nix
   # hosts/laptop/default.nix
   { config, lib, pkgs, hostname, ... }:
   {
     imports = [
       ./hardware-configuration.nix
       # Add any machine-specific modules
     ];
     
     # Machine-specific settings
   }
   ```

4. **Generate age key:**
   ```bash
   sudo mkdir -p /var/lib/sops/age
   sudo age-keygen -o /var/lib/sops/age/keys.txt
   sudo age-keygen -y /var/lib/sops/age/keys.txt  # Get public key
   ```

5. **Update `.sops.yaml`:**
   ```yaml
   - path_regex: secrets/laptop\.yaml$
     key_groups:
       - age:
           - <new-age-public-key>
   ```

6. **Create secrets file:**
   ```bash
   cp secrets/reason.yaml secrets/laptop.yaml
   sops secrets/laptop.yaml  # Edit as needed
   ```

7. **Add to flake.nix:**
   ```nix
   hosts = {
     reason = { ... };
     laptop = {
       hostname = "laptop";
       modules = [ ./profiles/minimal.nix ];
     };
   };
   
   users = {
     joachim = {
       username = "joachim";
       hosts = [ "reason" "laptop" ];  # Add laptop here
     };
   };
   ```

8. **Deploy:**
   ```bash
   sudo nixos-rebuild switch --flake .#laptop
   home-manager switch --flake .#joachim@laptop
   ```

## 👥 Adding New Users

1. **Create user directory:**
   ```bash
   mkdir -p users/newuser
   ```

2. **Create user config:**
   ```nix
   # users/newuser/default.nix
   { config, pkgs, lib, username, host, ... }:
   {
     home.packages = with pkgs; [
       # User-specific packages
     ];
     
     programs.git = {
       userName = "User Name";
       userEmail = "email@example.com";
     };
   }
   ```

3. **Add to flake.nix:**
   ```nix
   users = {
     joachim = { ... };
     newuser = {
       username = "newuser";
       hosts = [ "reason" ];  # Which machines this user uses
     };
   };
   ```

4. **Add system user (in appropriate host config):**
   ```nix
   users.users.newuser = {
     isNormalUser = true;
     extraGroups = [ "wheel" "networkmanager" ];
     shell = pkgs.fish;
   };
   ```

5. **Deploy:**
   ```bash
   sudo nixos-rebuild switch --flake .#reason  # Add system user
   home-manager switch --flake .#newuser@reason  # Set up home
   ```

## 🔍 Key Differences

### Before
```bash
sudo nixos-rebuild switch --flake .#reason
home-manager switch --flake .#joachim
```

### After
```bash
sudo nixos-rebuild switch --flake .#reason
home-manager switch --flake .#joachim@reason
```

Note the `@hostname` suffix for home-manager!

## 📁 Directory Layout

```
.
├── lib/                    # Builder functions
│   ├── default.nix        # Main lib export
│   ├── hosts.nix          # mkHost function
│   └── users.nix          # mkUser function
├── hosts/                 # System configurations
│   ├── reason/           # Desktop PC
│   │   ├── default.nix  # Machine-specific
│   │   └── hardware-configuration.nix
│   └── shared/           # Common system config
│       └── default.nix
├── users/                # User configurations
│   ├── joachim/         # User-specific
│   │   ├── default.nix
│   │   └── reason.nix   # Host-specific user config
│   └── shared/          # Shared programs
│       ├── home.nix
│       └── programs/
├── modules/             # Feature modules
│   └── nvidia.nix
├── profiles/            # Setup profiles
│   ├── desktop.nix
│   └── development.nix
└── secrets/             # Per-host secrets
    └── reason.yaml
```

## ⚠️ Important Notes

1. **Old Directories Still Exist:**
   - `system/` - Still used for some modules (will migrate fully later)
   - `dotfiles/` - Original location (can be removed after testing)
   
2. **Secrets:**
   - Each machine needs its own age key
   - Secrets are now in `secrets/<hostname>.yaml`
   - Old `secrets.yaml` still exists as fallback

3. **Testing:**
   - Test on current machine first: `sudo nixos-rebuild test --flake .#reason`
   - Verify home-manager: `home-manager switch --flake .#joachim@reason`
   
4. **Rollback:**
   - The previous configuration is still in git history
   - Can rollback with: `git checkout <previous-commit>`

## 🎯 Next Steps

1. **Test the new configuration:**
   ```bash
   sudo nixos-rebuild test --flake .#reason
   home-manager switch --flake .#joachim@reason
   ```

2. **If everything works:**
   ```bash
   sudo nixos-rebuild switch --flake .#reason
   ```

3. **Clean up (optional):**
   - Can remove old `dotfiles/` after confirming everything works
   - Can remove old `system/configuration.nix` after migrating remaining bits

4. **Add more machines:**
   - Follow "Adding New Machines" guide above

## 📚 Resources

- See `MULTI_MACHINE_PLAN.md` for detailed architecture
- See `README.md` for general usage
- See `COPILOT.md` and `GEMINI.md` for best practices

The configuration is now ready for multi-machine deployment! 🎉
