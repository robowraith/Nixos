# NixOS Configuration

A comprehensive NixOS and Home Manager configuration using flakes, featuring modular system organization, declarative dotfiles management, and encrypted secrets handling.

## 📋 Table of Contents

- [Features](#features)
- [Structure](#structure)
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Daily Usage](#daily-usage)
- [Secrets Management](#secrets-management)
- [Adding Programs](#adding-programs)
- [Rollback & Recovery](#rollback--recovery)
- [Tips & Best Practices](#tips--best-practices)

## ✨ Features

- **Flakes-based**: Reproducible and hermetic builds
- **Modular Organization**: Logical separation of system components
- **Home Manager Integration**: Declarative user environment and dotfiles
- **Encrypted Secrets**: SOPS-nix for secure credential management
- **Multiple Configurations**: Support for different users/machines
- **Automatic Cleanup**: Weekly garbage collection
- **Development Environment**: Built-in devShell for working with the config
- **Performance Optimized**: CachyOS kernel with LTO, binary cache enabled

## 📁 Structure

```
.
├── flake.nix                    # Main flake configuration
├── flake.lock                   # Locked dependency versions
├── .sops.yaml                   # SOPS encryption rules
├── secrets.yaml                 # Encrypted secrets (sops-encrypted)
├── system/
│   ├── configuration.nix        # Main system configuration
│   ├── hardware-configuration.nix  # Hardware-specific settings
│   ├── sops/
│   │   └── sops.nix            # System-level secrets config
│   └── modules/
│       ├── boot.nix            # Boot loader & kernel settings
│       ├── networking.nix      # Network configuration
│       ├── nvidia.nix          # NVIDIA GPU settings
│       ├── filesystems.nix     # CIFS mounts & filesystems
│       ├── users.nix           # User account definitions
│       └── localization.nix    # Locale, timezone, keyboard
└── dotfiles/
    ├── home.nix                # Main Home Manager config
    └── programs/               # Per-program configurations
        ├── fish/
        ├── git/
        ├── helix/
        └── ...                 # One directory per program
```

## 🔧 Prerequisites

- NixOS installed (minimal or desktop)
- Git installed
- Age key for decrypting secrets (see [Secrets Management](#secrets-management))

## 🚀 Initial Setup

### 1. Clone the Repository

```bash
git clone <your-repo-url> ~/nixos-config
cd ~/nixos-config
```

### 2. Generate Age Key (First Time Only)

```bash
# Create the sops directory
sudo mkdir -p /var/lib/sops/age

# Generate a new age key
sudo age-keygen -o /var/lib/sops/age/keys.txt

# Get your public key
sudo age-keygen -y /var/lib/sops/age/keys.txt
```

**⚠️ IMPORTANT**: Backup your age key! Store it securely outside your system.

```bash
# Backup example
sudo cp /var/lib/sops/age/keys.txt ~/backup/age-key-backup.txt
# Then move to secure location (encrypted USB, password manager, etc.)
```

### 3. Update .sops.yaml

Replace the age public key in `.sops.yaml` with your generated key:

```yaml
creation_rules:
  - path_regex: secrets.yaml$
    key_groups:
      - age:
          - age1your_actual_public_key_here
```

### 4. Create/Edit Secrets

```bash
# Edit secrets (will open in $EDITOR)
sops secrets.yaml
```

Add your credentials:

```yaml
system-secrets:
  cifs_credentials:
    username: your_network_username
    password: your_network_password
hm-secrets: null
```

### 5. Adjust Hardware Configuration

Update the network interface name in `system/modules/networking.nix`:

```bash
# Find your interface name
ip link

# Edit the file and replace 'enp7s0' with your interface
```

### 6. Build and Switch

```bash
# Build the system configuration
sudo nixos-rebuild switch --flake .#reason

# Build the home-manager configuration
home-manager switch --flake .#joachim
```

## 🔄 Daily Usage

### Updating the System

```bash
# Update flake inputs
nix flake update

# Or update specific inputs
nix flake lock --update-input nixpkgs

# Apply updates
sudo nixos-rebuild switch --flake .#reason
home-manager switch --flake .#joachim
```

### Testing Changes Before Applying

```bash
# Test system changes without switching boot default
sudo nixos-rebuild test --flake .#reason

# Build without activating
sudo nixos-rebuild build --flake .#reason
```

### Checking Configuration

```bash
# Format all Nix files
nix fmt

# Check for errors
nix flake check

# Enter development shell
nix develop
```

## 🔐 Secrets Management

### Viewing Secrets

```bash
sops secrets.yaml
```

### Adding New Secrets

1. Edit `secrets.yaml`:
   ```bash
   sops secrets.yaml
   ```

2. Add your secret:
   ```yaml
   system-secrets:
     my_new_secret: some_value
   ```

3. Reference in configuration:
   ```nix
   sops.secrets."my_new_secret" = {
     sopsFile = ../../secrets.yaml;
     key = "system-secrets/my_new_secret";
   };
   ```

### Rotating Age Keys

```bash
# Generate new key
sudo age-keygen -o /var/lib/sops/age/keys-new.txt

# Get public key
sudo age-keygen -y /var/lib/sops/age/keys-new.txt

# Update .sops.yaml with new public key

# Re-encrypt secrets with both old and new keys (temporarily)
sops updatekeys secrets.yaml

# Test that everything works, then remove old key
```

## ➕ Adding Programs

### Method 1: Simple Package Addition

1. Create directory: `dotfiles/programs/program-name/`
2. Create file: `program-name.nix`
3. Add configuration:

```nix
{ config, pkgs, ... }:

{
  programs.program-name = {
    enable = true;
    # ... configuration
  };
}
```

The package will be automatically installed if it exists in nixpkgs with the same name.

### Method 2: Explicit Package

If the package name differs from the directory name:

Edit `dotfiles/home.nix` and add to `home.packages`:

```nix
home.packages = with pkgs; [
  # ... existing packages
  actual-package-name
];
```

### Method 3: Custom Package

For packages not in nixpkgs:

```nix
{ config, pkgs, ... }:

let
  customPackage = pkgs.stdenv.mkDerivation {
    # ... derivation
  };
in
{
  home.packages = [ customPackage ];
}
```

## 🔙 Rollback & Recovery

### System Rollback

```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or select specific generation
sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation <number>
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

### Home Manager Rollback

```bash
# List generations
home-manager generations

# Activate specific generation
/nix/store/<hash>-home-manager-generation/activate
```

### Boot Menu Recovery

At boot, select an older generation from the systemd-boot menu.

### Emergency Access

If the system fails to boot:
1. Select an older generation from boot menu
2. Or boot into recovery mode
3. Access TTY1 (emergency shell is enabled)

## 💡 Tips & Best Practices

### Performance

- **Binary Cache**: Chaotic Nyx cache is configured for faster CachyOS kernel builds
- **Garbage Collection**: Runs weekly, keeps last 30 days
- **Build Optimization**: Use `--cores 0` for parallel builds

### Security

- **SSH**: Root login disabled, password authentication disabled
- **Secrets**: Never commit unencrypted secrets
- **Age Key**: Keep multiple encrypted backups in different locations

### Maintenance

```bash
# Clean old generations manually
sudo nix-collect-garbage --delete-older-than 30d

# Optimize Nix store
nix-store --optimise

# Repair Nix store
nix-store --verify --check-contents --repair
```

### Git Workflow

```bash
# Before making changes
git checkout -b feature/my-changes

# After testing
git add .
git commit -m "description of changes"
git push origin feature/my-changes

# After reviewing
git checkout main
git merge feature/my-changes
```

### Multi-Machine Setup

1. Create new user config in `flake.nix`:
   ```nix
   userConfigs = {
     joachim = { ... };
     work = {
       username = "work-user";
       homeDirectory = "/home/work-user";
     };
   };
   ```

2. Create new system config:
   ```nix
   nixosConfigurations.work-machine = nixpkgs.lib.nixosSystem {
     # ... configuration
   };
   ```

3. Deploy:
   ```bash
   sudo nixos-rebuild switch --flake .#work-machine
   home-manager switch --flake .#work
   ```

## 🐛 Troubleshooting

### "error: access to URI is forbidden"

Make sure all files are tracked in git:
```bash
git add .
```

### Secrets not decrypting

1. Check age key exists: `sudo cat /var/lib/sops/age/keys.txt`
2. Verify public key matches in `.sops.yaml`
3. Re-encrypt: `sops updatekeys secrets.yaml`

### Network shares not mounting

1. Check credentials: `sudo cat /etc/cifs-credentials`
2. Verify network connectivity to NAS
3. Check mount points exist
4. Review logs: `journalctl -u 'home-joachim-*.mount'`

### Hyprland not starting

1. Check NVIDIA drivers loaded: `lsmod | grep nvidia`
2. Verify Wayland variables: `echo $NIXOS_OZONE_WL`
3. Try from TTY: `Hyprland`
4. Check logs: `journalctl -b | grep hyprland`

## 📚 Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [SOPS-nix Documentation](https://github.com/Mic92/sops-nix)
- [Nix Flakes Wiki](https://nixos.wiki/wiki/Flakes)
- [CachyOS Kernel](https://github.com/CachyOS/linux-cachyos)

## 📝 License

This configuration is provided as-is for personal use. Adapt as needed.

## 🤝 Contributing

This is a personal configuration, but suggestions are welcome via issues or pull requests.
