{
  hostname,
  lib,
  ...
}: {
  # ============================================================================
  # Networking
  # ============================================================================
  # dumont is the LAN's DHCP server, so its own address is static.
  # IPv6 comes from the Speedport's router advertisements (ULA + GUA prefix);
  # the token gives a predictable <prefix>::2 address that, unlike EUI-64,
  # does not encode the MAC.

  networking = {
    hostName = hostname;

    # Pi-hole answers on :53 itself; resolved's stub listener would get in
    # its way. Fall back to a public resolver so dumont can still fetch
    # blocklists and updates while FTL is down.
    nameservers = ["127.0.0.1" "9.9.9.9"];

    # Services answer the LAN only. dumont also has a global IPv6 address,
    # so without source rules SSH and the web UI would be exposed as soon as
    # the Speedport's inbound IPv6 filter were ever off. The ULA range is
    # written generically (fc00::/7) to keep the real prefix out of the repo.
    nftables.enable = true;
    firewall = {
      # system/shared opens 22 to everyone; here every TCP port goes
      # through the source rules below
      allowedTCPPorts = lib.mkForce [];
      # DHCP requests come from 0.0.0.0 (broadcast), so no source filter
      allowedUDPPorts = [67];
      extraInputRules = ''
        ip saddr 192.168.1.0/24 tcp dport { 22, 53, 80 } accept
        ip saddr 192.168.1.0/24 udp dport 53 accept
        ip6 saddr { fe80::/10, fc00::/7 } tcp dport { 22, 53, 80 } accept
        ip6 saddr { fe80::/10, fc00::/7 } udp dport 53 accept
      '';
    };
  };

  # Port 22 is opened above for LAN sources only
  services.openssh.openFirewall = false;

  services.resolved.enable = false;

  systemd.network.networks."10-lan" = {
    # The 3040 has a single wired NIC; match it by type, not by name
    matchConfig.Type = "ether";
    address = ["192.168.1.2/24"];
    gateway = ["192.168.1.1"];
    networkConfig = {
      IPv6AcceptRA = true;
      IPv6PrivacyExtensions = "no";
    };
    ipv6AcceptRAConfig = {
      Token = "static:::2";
      # Pi-hole is the LAN's resolver; don't take the Speedport's from RAs
      UseDNS = false;
    };
    linkConfig.RequiredForOnline = "routable";
  };
}
