# Spec Delta

## Purpose

Provides name resolution, ad and tracker blocking, DNSSEC validation and address assignment for every device on the
home LAN from a dedicated host, with configuration that is reproducible from the repository.

## ADDED Requirements

### Requirement: LAN DNS resolution with blocking
dumont SHALL answer DNS queries over UDP and TCP on port 53 at `192.168.1.2` and at its stable IPv6 ULA address. It
SHALL return `0.0.0.0` (or `::` for AAAA) for domains on the configured blocklists and normal answers for all other
domains.

#### Scenario: Normal lookup
- **WHEN** a LAN client queries `example.com` at `192.168.1.2`
- **THEN** dumont returns the public address records with status NOERROR

#### Scenario: Blocked domain
- **WHEN** a LAN client queries `doubleclick.net` at `192.168.1.2`
- **THEN** dumont returns `0.0.0.0`

#### Scenario: Lookup over IPv6
- **WHEN** a client queries `example.com` at dumont's ULA address
- **THEN** dumont returns the same answer as over IPv4

### Requirement: DNSSEC validation with current root anchors
dumont SHALL validate DNSSEC using a trust-anchor set that includes the root KSK-2024 (key tag 38696). It SHALL NOT
rely on a hand-placed trust-anchor file.

#### Scenario: Validly signed zone
- **WHEN** a client queries a correctly signed domain
- **THEN** dumont answers NOERROR

#### Scenario: Deliberately broken zone
- **WHEN** a client queries `dnssec-failed.org`
- **THEN** dumont answers SERVFAIL

### Requirement: Local names for LAN devices
dumont SHALL resolve the `meine2cent.home` names of LAN devices as configured in the device inventory, and it SHALL
resolve each name to exactly one IPv4 address.

#### Scenario: Known device name
- **WHEN** a client queries a device name from the inventory, e.g. `wintermute.meine2cent.home`
- **THEN** dumont returns that device's single configured address

### Requirement: DHCP for the LAN
Once cut over, dumont SHALL be the only DHCPv4 server on the LAN, except while DHCP has failed over to wintermute's
cold standby. It SHALL hand out gateway `192.168.1.1` and DNS
server `192.168.1.2`, assign reserved addresses to inventory devices by MAC, and answer requests for leases it has no
record of (authoritative mode). It SHALL NOT send IPv6 Router Advertisements.

#### Scenario: Reserved device reconnects
- **WHEN** a device with a reservation sends DHCPDISCOVER
- **THEN** it receives its reserved IPv4 address, gateway `192.168.1.1` and DNS server `192.168.1.2`

#### Scenario: Client rebinds a lease issued by wintermute
- **WHEN** a client holding a lease from wintermute sends DHCPREQUEST after wintermute's DHCP has been turned off
- **THEN** dumont answers with an ACK or NAK instead of ignoring the request

#### Scenario: No router advertisements
- **WHEN** `rdisc6` is run on a LAN host
- **THEN** only the Speedport (`fe80::1`) answers

### Requirement: Cold-standby DHCP on wintermute
wintermute SHALL keep a DHCP configuration matching dumont's (range, gateway, reservations) with DHCP turned off, so
DHCP can be moved to it by hand while dumont is down. At most one of the two SHALL serve DHCP at any time.

#### Scenario: Normal operation
- **WHEN** dumont is up
- **THEN** nothing listens on wintermute's UDP port 67

#### Scenario: Failover
- **WHEN** dumont is down and DHCP is turned on at wintermute
- **THEN** a reconnecting reserved device receives its reserved address and gateway `192.168.1.1` from wintermute

#### Scenario: Failback
- **WHEN** dumont serves DHCP again
- **THEN** wintermute's DHCP is already off, and a client holding a wintermute lease gets an ACK or NAK from dumont
  when it rebinds

### Requirement: Configuration is reproducible from the repository
All Pi-hole configuration — settings, blocklists, allowlist, DHCP reservations and local DNS records — SHALL come
from the flake and its sops secrets. A redeploy SHALL restore it regardless of changes made through the web UI.

#### Scenario: UI change does not survive a deploy
- **WHEN** a setting is changed in dumont's web UI and dumont is then redeployed
- **THEN** the setting matches the repository again

#### Scenario: Fresh install
- **WHEN** dumont is reinstalled from the flake
- **THEN** DNS, blocking, local names and DHCP reservations work without any manual configuration step in Pi-hole

### Requirement: Device inventory stays private
MAC addresses, the list of reserved devices and dumont's EUI-64 interface identifier SHALL NOT appear in plaintext in
the repository. They SHALL live only in sops-encrypted files.

#### Scenario: Searching the repo for MACs
- **WHEN** the tracked files are searched for MAC-address patterns
- **THEN** no match comes from dumont's configuration or from this change's documents

### Requirement: Cutover keeps DNS reachable and DHCP singular
Moving DNS/DHCP from wintermute to dumont SHALL never leave two DHCPv4 servers active at once. Every client SHALL
keep a reachable DNS server throughout. Rollback to wintermute SHALL be possible until the cleanup phase starts.

#### Scenario: DHCP handover
- **WHEN** DHCP is enabled on dumont
- **THEN** DHCP on wintermute has already been disabled

#### Scenario: Clients still pointed at wintermute
- **WHEN** a client still uses `192.168.1.3` as its DNS server after DHCP has moved
- **THEN** wintermute's Pi-hole still answers its queries until wintermute's query log has shown no client queries for
  at least one full lease period

#### Scenario: Rollback before cleanup
- **WHEN** a problem appears on dumont before the cleanup phase
- **THEN** disabling DHCP on dumont, repointing the Speedport and restoring wintermute's Pi-hole brings the LAN back to
  the pre-cutover state with no data restore needed
