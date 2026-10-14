# Spec Delta

## Purpose

Defines how fleet hosts that are not the operator's current machine are installed and changed: built elsewhere,
activated in a way that can be reverted, and always run by the user rather than by an assistant.

## ADDED Requirements

### Requirement: Off-host builds
Deploying to dumont SHALL evaluate and build on the deploying machine (reason or deepthought, later wintermute) and
copy only the finished closure to dumont. dumont SHALL NOT need to evaluate the flake itself.

#### Scenario: Deploy from reason
- **WHEN** the user deploys dumont from reason
- **THEN** evaluation and builds run on reason, and dumont only receives store paths

### Requirement: Reproducible first install
dumont SHALL be installable from the flake in one remote command against the NixOS installer. The command SHALL
create the disk layout declared in the repository and place the host's pre-generated SSH host key, so that sops
secrets decrypt on first boot.

#### Scenario: Reinstall from scratch
- **WHEN** dumont is booted from the NixOS installer and the install command is run from reason
- **THEN** dumont boots into its configuration with its known SSH host key and decrypted secrets, with no manual
  partitioning

### Requirement: Guarded activation with automatic revert
The deploy command for dumont SHALL activate a new generation without making it the boot default. It SHALL then
check from the deploying machine that:
- DNS resolves at `192.168.1.2`
- a blocked domain returns `0.0.0.0`
- SSH is reachable
- `pihole-FTL` is active

Only after all checks pass SHALL it make the generation the boot default. If any check fails, it SHALL re-activate
the previous generation and exit non-zero.

#### Scenario: Healthy deploy
- **WHEN** the new generation passes all health checks
- **THEN** it becomes the boot default and the command exits zero

#### Scenario: Pi-hole fails to start
- **WHEN** `pihole-FTL` is not active after activation
- **THEN** the previous generation is re-activated, DNS answers again, and the command exits non-zero naming the
  failed check

#### Scenario: SSH lost after activation
- **WHEN** dumont is unreachable over SSH after activation
- **THEN** power-cycling dumont boots the previous boot-default generation

### Requirement: Deploys reach dumont without DNS
The deploy and rollback paths SHALL address dumont by IP address, so that they work while LAN DNS is down.

#### Scenario: Rollback during a DNS outage
- **WHEN** dumont's DNS is down and the user rolls back from reason
- **THEN** the rollback reaches dumont and completes without any name resolution

### Requirement: Rebuilds stay the user's job
Install, deploy, switch and rollback commands that need sudo SHALL be run by the user. An assistant working in this
repository SHALL only prepare and print them, together with read-only checks.

#### Scenario: Assistant reaches a deploy step
- **WHEN** an implementation task requires deploying dumont
- **THEN** the assistant prints the exact command and waits for the user's result
