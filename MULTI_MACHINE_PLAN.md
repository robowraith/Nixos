# Multi-Computer and Multi-User Configuration Plan

## 🎯 Goal

Transform the current single-machine configuration into a flexible multi-computer, multi-user setup that:
- Supports multiple machines with different hardware
- Supports multiple users with shared and unique configurations
- Maintains modularity and DRY principles
- Allows easy deployment to different machines

## 📋 Current State Analysis

**Current Structure:**
- Single NixOS configuration: `reason`
- Single user setup: `joachim`
- Hardcoded hostname and user in various places
- Shared configuration for all potential users/machines

**Limitations:**
- Cannot easily deploy to different machines
- No per-machine customization
- User-specific settings mixed with system settings
- Difficult to share common config while allowing differences

## 🏗️ Proposed Architecture

### Directory Structure

```
.
├── flake.nix                      # Main flake with all outputs
├── .sops.yaml                     # Multi-machine sops config
├── secrets/                       # Per-machine/user secrets
│   ├── reason.yaml               # Desktop secrets
│   ├── laptop.yaml               # Laptop secrets
│   └── shared.yaml               # Shared secrets
├── lib/                          # Helper functions
│   ├── default.nix               # Main lib export
│   ├── hosts.nix                 # Host builder functions
│   └── users.nix                 # User builder functions
├── hosts/                        # Per-machine configurations
│   ├── reason/                   # Desktop PC
│   │   ├── default.nix          # Machine-specific config
│   │   ├── hardware-configuration.nix
│   │   └── secrets.nix          # Machine secrets config
│   ├── laptop/                   # Future laptop
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   └── shared/                   # Shared system config
│       ├── default.nix          # Common system settings
│       ├── boot.nix
│       ├── networking.nix
│       ├── security.nix
│       └── services.nix
├── modules/                      # Reusable NixOS modules
│   ├── nvidia.nix               # NVIDIA configuration module
│   ├── gaming.nix               # Gaming setup module
│   ├── development.nix          # Dev tools module
│   └── cifs-mounts.nix         # CIFS mount module
├── users/                        # Per-user configurations
│   ├── joachim/                 # Primary user
│   │   ├── default.nix         # User-specific home config
│   │   ├── desktop.nix         # Desktop-specific settings
│   │   ├── laptop.nix          # Laptop-specific settings
│   │   └── programs/           # User-specific programs
│   ├── work/                    # Work user (future)
│   │   └── default.nix
│   └── shared/                  # Shared user config
│       ├── default.nix         # Common user settings
│       └── programs/           # Shared programs
│           ├── fish/
│           ├── git/
│           ├── helix/
│           └── ...
└── profiles/                     # Feature profiles
    ├── desktop.nix              # Desktop environment profile
    ├── development.nix          # Development setup
    ├── gaming.nix               # Gaming profile
    └── minimal.nix              # Minimal server profile
```

## 🔧 Implementation Steps

### Phase 1: Restructure for Multiple Hosts

#### 1.1 Create Host Configuration System

**Create `lib/hosts.nix`:**
```nix
{ inputs, ... }:
{
  mkHost = { hostname, system ? "x86_64-linux", modules ? [], users ? [] }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs hostname; };
      modules = [
        inputs.sops-nix.nixosModules.sops
        ../hosts/${hostname}
        ../hosts/shared
      ] ++ modules;
    };
}
```

#### 1.2 Move Current Config to hosts/reason/

**Actions:**
- Move `system/configuration.nix` → `hosts/reason/default.nix`
- Move `system/hardware-configuration.nix` → `hosts/reason/hardware-configuration.nix`
- Move `system/modules/*` → `hosts/shared/` (common configs)
- Keep machine-specific in `hosts/reason/`

#### 1.3 Create Shared System Config

**Create `hosts/shared/default.nix`:**
- Nix settings (flakes, caches, GC)
- Common packages
- Security defaults
- Common services

### Phase 2: Restructure for Multiple Users

#### 2.1 Create User Configuration System

**Create `lib/users.nix`:**
```nix
{ inputs, ... }:
{
  mkUser = { username, extraModules ? [], extraPackages ? [], host ? null }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = { inherit inputs username host; };
      modules = [
        inputs.stylix.homeModules.stylix
        inputs.sops-nix.homeManagerModules.sops
        ../users/${username}
        ../users/shared
      ] ++ extraModules ++ (
        if host != null then [ ../users/${username}/${host}.nix ] else []
      );
    };
}
```

#### 2.2 Reorganize User Configs

**Actions:**
- Move `dotfiles/` → `users/shared/` (common programs)
- Create `users/joachim/default.nix` (user-specific settings)
- Create `users/joachim/desktop.nix` (machine-specific user config)
- Separate user-specific from shared program configs

### Phase 3: Create Reusable Modules

#### 3.1 Feature Modules

**Create modules for optional features:**
- `modules/nvidia.nix` - NVIDIA GPU setup
- `modules/gaming.nix` - Steam, gaming tools
- `modules/development.nix` - Dev environments
- `modules/cifs-mounts.nix` - NAS mount configurations

**Usage pattern:**
```nix
# In host config
imports = [
  ../../modules/nvidia.nix
  ../../modules/gaming.nix
];
```

#### 3.2 Profile System

**Create `profiles/` for common setups:**
- `desktop.nix` - Full desktop environment
- `development.nix` - Developer workstation
- `minimal.nix` - Server/minimal setup

### Phase 4: Multi-User Secrets Management

#### 4.1 Restructure Secrets

**Update `.sops.yaml`:**
```yaml
creation_rules:
  # Shared secrets
  - path_regex: secrets/shared.yaml$
    key_groups:
      - age: [key1, key2, key3]
  
  # Per-host secrets
  - path_regex: secrets/reason.yaml$
    key_groups:
      - age: [reason-key]
  
  - path_regex: secrets/laptop.yaml$
    key_groups:
      - age: [laptop-key]
```

#### 4.2 Per-Machine Age Keys

- Generate unique age key per machine
- Store in `/var/lib/sops/age/keys.txt` on each machine
- Update secrets with all machine keys
- Use hostname-based secret files

### Phase 5: Update Flake Configuration

#### 5.1 New Flake Structure

**Update `flake.nix`:**
```nix
{
  outputs = { self, nixpkgs, ... }@inputs:
    let
      lib = import ./lib { inherit inputs; };
      
      # Define all hosts
      hosts = {
        reason = {
          hostname = "reason";
          modules = [
            ./modules/nvidia.nix
            ./modules/gaming.nix
            chaotic.nixosModules.default
          ];
        };
        laptop = {
          hostname = "laptop";
          modules = [
            ./profiles/minimal.nix
          ];
        };
      };
      
      # Define all users
      users = {
        joachim = {
          username = "joachim";
          hosts = [ "reason" "laptop" ];
        };
        work = {
          username = "work-user";
          hosts = [ "laptop" ];
        };
      };
      
    in {
      # Generate NixOS configurations for all hosts
      nixosConfigurations = builtins.mapAttrs 
        (name: config: lib.hosts.mkHost config) 
        hosts;
      
      # Generate Home Manager configs for all user@host combinations
      homeConfigurations = 
        builtins.listToAttrs (
          lib.lists.flatten (
            builtins.map (userName:
              let userConfig = users.${userName};
              in builtins.map (host: {
                name = "${userName}@${host}";
                value = lib.users.mkUser {
                  inherit (userConfig) username;
                  inherit host;
                };
              }) userConfig.hosts
            ) (builtins.attrNames users)
          )
        );
      
      # Development shell
      devShells.x86_64-linux.default = ...;
      formatter.x86_64-linux = ...;
    };
}
```

## 📝 Migration Path

### Step 1: Backup Current Config
```bash
git checkout -b backup-single-machine
git push origin backup-single-machine
```

### Step 2: Create New Structure
```bash
git checkout -b multi-host-refactor

# Create new directories
mkdir -p {lib,hosts/{reason,shared},users/{joachim,shared},modules,profiles,secrets}

# Move files to new locations
# (specific commands in implementation)
```

### Step 3: Test on Current Machine
```bash
# Build test
sudo nixos-rebuild build --flake .#reason

# Test without switching
sudo nixos-rebuild test --flake .#reason

# Apply if successful
sudo nixos-rebuild switch --flake .#reason
home-manager switch --flake .#joachim@reason
```

### Step 4: Add Second Machine
```bash
# On new machine, generate hardware config
nixos-generate-config --show-hardware-config > hosts/laptop/hardware-configuration.nix

# Create machine config
# Edit hosts/laptop/default.nix

# Generate age key
sudo mkdir -p /var/lib/sops/age
sudo age-keygen -o /var/lib/sops/age/keys.txt

# Update .sops.yaml with new key
# Create secrets/laptop.yaml

# Deploy
sudo nixos-rebuild switch --flake .#laptop
home-manager switch --flake .#joachim@laptop
```

## 🎁 Benefits

1. **Scalability**: Easy to add new machines and users
2. **Sharing**: Common config shared, specific config separated
3. **Maintainability**: Clear structure, logical organization
4. **Flexibility**: Per-machine customization, per-user settings
5. **Security**: Per-machine secrets, proper isolation
6. **DRY**: No duplication, reusable modules
7. **Testing**: Test changes on one machine before deploying to others

## 🔄 Usage After Migration

### Deploy to specific machine:
```bash
sudo nixos-rebuild switch --flake .#reason
sudo nixos-rebuild switch --flake .#laptop
```

### Deploy for specific user on specific machine:
```bash
home-manager switch --flake .#joachim@reason
home-manager switch --flake .#joachim@laptop
home-manager switch --flake .#work@laptop
```

### Add new machine:
1. Create `hosts/newmachine/` directory
2. Add hardware-configuration.nix
3. Create default.nix with machine-specific settings
4. Add to `hosts` in flake.nix
5. Generate age key and update secrets

### Add new user:
1. Create `users/newuser/` directory
2. Create default.nix with user settings
3. Add to `users` in flake.nix
4. Optionally create per-host configs

## ⚠️ Considerations

1. **Secrets**: Each machine needs its own age key
2. **State**: Home-manager state is per-user@host combination
3. **Deployment**: Consider using deploy-rs for remote deployment
4. **Testing**: Test on non-critical machine first
5. **Documentation**: Update README with new structure
6. **Git**: Ensure all new files are tracked before building

## 🚀 Future Enhancements

1. **Remote Deployment**: Use deploy-rs or colmena
2. **Shared Overlays**: Custom packages available to all machines
3. **CI/CD**: Automated testing of configurations
4. **Secrets Backend**: Consider using age-plugin-yubikey
5. **Modular Profiles**: More granular feature profiles
6. **Cross-Platform**: Support for Darwin (macOS)

This plan provides a clear path from the current single-machine setup to a scalable multi-machine, multi-user configuration while maintaining best practices and modularity.
