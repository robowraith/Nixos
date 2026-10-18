# Spec Delta

## Purpose

Defines what each class of fleet host contains, so that servers and appliances stay minimal while desktops keep
their full environment, and limits which secrets each host can decrypt.

## ADDED Requirements

### Requirement: Server hosts are minimal
A host in the `server` hostgroup SHALL NOT include a desktop session, Docker, Home Manager, Stylix theming,
Plymouth, fonts for graphical use, or the desktop kernel (CachyOS, currently Zen). It SHALL include SSH, sops, Nix garbage collection and the
shared base CLI tools.

#### Scenario: Inspecting dumont's system
- **WHEN** dumont's toplevel closure is inspected
- **THEN** it contains no Docker daemon, no Home Manager generation and no X/Wayland session

### Requirement: Desktop hosts are unchanged by the split
Restructuring the shared layer SHALL NOT change reason's or deepthought's system configurations.

#### Scenario: Comparing desktop builds
- **WHEN** reason's and deepthought's toplevel derivations are evaluated before and after the restructuring
- **THEN** the derivation paths are identical. If not, a closure diff shows no added, removed or changed packages or
  services, and every remaining difference is explained in the change

### Requirement: Small-disk hosts keep free space
A host with storage below 16 GB SHALL keep enough free space for one more deploy. Old generations SHALL be
garbage-collected automatically, and the number of boot entries SHALL be limited so the EFI partition cannot fill up.

#### Scenario: Repeated deploys
- **WHEN** dumont has been deployed ten times over several weeks
- **THEN** free space on the root filesystem remains above the size of one system closure, and the EFI partition is
  not full

### Requirement: Secrets are scoped per host
A host with its own sops identity SHALL be able to decrypt only its own secrets file. It SHALL NOT hold the shared
age key. The shared key SHALL remain a recipient of every secrets file, so the operator can edit them from a desktop.

#### Scenario: dumont tries to read shared secrets
- **WHEN** `secrets/shared.yaml` is decrypted on dumont using dumont's identity
- **THEN** decryption fails

#### Scenario: Operator edits dumont's secrets
- **WHEN** the operator runs `sops secrets/dumont.yaml` on reason
- **THEN** the file opens for editing using the shared key
