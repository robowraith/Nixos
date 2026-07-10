# Dendritic Nix Configuration

A personal approach to a modular, scalable, and "Dendritic" NixOS and Home Manager configuration.

## 🖥️ Systems Overview

See [docs/hosts.md](docs/hosts.md) for the full fleet reference, including
migration status of hosts not yet on NixOS.

## 🧭 Guiding Principles

### Core Philosophy
1.  **Nix Flakes**: Utilize Nix Flakes for reproducible and hermetic project structure.
2.  **Dendritic Structure**: Organize configuration in a tree-like, branching structure for modularity (inspired by [vic/dendrix](https://github.com/vic/dendrix)).
3.  **DRY (Don't Repeat Yourself)**: Maximize code reuse across systems and users.
4.  **Nix-Native**: Prefer Nix language configuration over external config files where possible.

### Configuration Management
5.  **Split Configuration**:
    *   `system/`: NixOS system-level configurations.
    *   `dotfiles/`: Home Manager user-level configurations.
6.  **Atomic Organization**: One folder per program/service (unless trivial).
7.  **Cascading Logic**:
    *   **System**: `Shared` -> `Hostgroup` -> `Host`.
    *   **User**: `Shared` -> `Usergroup` -> `Host-Specific` -> `User`.
    *   Selection logic driven by variables defined in `flake.nix` passed via `specialArgs` (NixOS) and `extraSpecialArgs` (Home Manager).
8.  **Config Linking**: `home.programs` should link configuration files from the store (e.g., `fish/config.fish` links to `~/.config/fish/config.fish`).

### Security & Networking
9.  **Secrets Management**: All secrets must be encrypted using **SOPS** (`sops-nix`).
10. **Connectivity**: All systems reachable via SSH.
11. **Defense**:
    *   **Firewall**: `nftables` enabled on all hosts.
    *   **Intrusion Prevention**: `fail2ban` enabled for all open ports.

### Environment & Packages
12. **Nixpkgs**: Track `nixpkgs-unstable` for latest software.
13. **Binary Cache**: Utilize **Chaotic-Nyx** for pre-built binaries.
14. **Shell**: **Fish** shell as the default for all users.
15. **Maintenance**: Automatic garbage collection and store optimization for both NixOS and Home Manager.
16. **Theming**: Use **Stylix** for unified system-wide theming (NixOS & Home Manager).

## 🛠️ Best Practices & Tooling

### Formatting
Code consistency is enforced using **Alejandra** (or `nixfmt`).
*   **Usage**:
    ```bash
    nix fmt
    # or directly
    alejandra .
    ```

### Linting
Static analysis helps catch errors and unused code early.
*   **Statix**: Checks for anti-patterns and suggestions.
    ```bash
    statix check .
    statix fix . # Automatically fix issues
    ```
*   **Deadnix**: Scans for unused variable bindings.
    ```bash
    deadnix .
    deadnix -e . # Automatically remove unused code
    ```

### Pre-commit Hooks
To ensure quality before pushing, `pre-commit-hooks.nix` is used to run checks automatically.
*   **Setup**: Run `nix develop` to enter the dev shell which installs the hooks.
*   **Manual Run**:
    ```bash
    pre-commit run --all-files
    ```

### Documentation
Practical documentation for secrets and security is provided in the `docs/` folder:
- `docs/SOPS.md`: Practical `sops` and `sops-nix` usage, commands, and examples.
- `docs/SECURITY.md`: Repo hygiene, key rotation, backup and incident response guidance.

## 📂 Directory Structure (Target)

```
.
├── dotfiles/
│   ├── shared/
│   │   ├── modules/                           # Configuration modules for all users
│   │   ├── programs/                          # Cofiguration directory for home.programs for all users
│   │   │   ├── _uninstalled/                  # Configuration data for programs which should be kept although the programs are not installed at the moment
│   │   │   │   └── {program2}/                # Configuration directory for "program"
│   │   │   │       └── {program2}.nix         # Configures "program2"
│   │   │   └── {program1}/                    # Configuration directory for "program1"
│   │   │       └── {program1}.nix             # Configures "program1"
│   │   └── default.nix                        # Imports all configuration modules from ./modules and all programs from ./programs/ not in ./program/_uninstalled/
│   ├── usergroups/
│   │   └── {usergroup1}/
│   │       ├── modules/                       # Configuration modules specific to "usergroup1"
│   │       ├── programs/                      # Cofiguration directory for home.programs for "usergroup1"
│   │       │   ├── _uninstalled/              # Configuration data for programs which should be kept although the programs are not installed at the moment
│   │       │   │   └── {program2}/            # Configuration directory for "program"
│   │       │   │       └── {program2}.nix     # Configures "program2"
│   │       │   └── {program1}/                # Configuration directory for "program1"
│   │       │       └── {program1}.nix         # Configures "program1". May import configuration from dotfiles/shared/programs/program1.nix
│   │       └── default.nix                    # Imports all configuration modules from ./modules and all programs from ./programs/ not in ./program/_uninstalled/
│   └── users/
│       └── {user1}/                           # Configuration directory for "user1"
│           ├── modules/                       # Configuration modules specific to "user1"
│           ├── programs/                      # Cofiguration directory for home.programs for "user1"
│           │   └── _uninstalled/              # Configuration data for programs which should be kept although the programs are not installed at the moment
│           │       │   └── {program2}/        # Configuration directory for "program"
│           │       │       └── {program2}.nix # Configures "program2"
│           │       └── {program1}/            # Configuration directory for "program1"
│           │           └── {program1}.nix     # Configures "program1". May import configuration from dotfiles/shared/programs/program1.nix or dotfiles/usergroups/{usergroup}/programs/program1.nix
│           └── default.nix                    # Imports all configuration modules from ./modules and all programs from ./programs/ not in ./program/_uninstalled/
├── secrets/                                   # The SOPS-encrypted secrets
│   └── shared.yml                             # Secrets shared by all systems/users
├── system/
│   ├── hostgroups/
│   │   └── {hostgroup1}/                      # Configuration directory for "hostgroup1"
│   │       ├── modules/                       # Configuration modules specific to this hostgroup
│   │       └── default.nix                    # Imports all configuration modules from ./modules
│   ├── hosts/
│   │   └── {host1}/                           # Configuration directory for "host1"
│   │       ├── modules/                       # Configuration modules specific to this host
│   │       └── default.nix                    # MAIN TARGET -> imports all configuration for this host
│   └── shared/                                # Configuration directory for all systems
│       ├── modules/                           # Configuration modules shared by all systems
│       └── default.nix                        # Imports all configuration modules in ./modules
├── flake.nix                                  # Main flake configuration for NixOS and Home Manager
├── flake.lock                                 # Locked dependecy versions
├── README.md                                  # This Document
└── .sops.yaml                                 # The SOPS rules file for this project

