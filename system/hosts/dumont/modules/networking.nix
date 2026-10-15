{hostname, ...}: {
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

    firewall = {
      allowedTCPPorts = [
        53 # DNS
        80 # Pi-hole web UI
      ];
      allowedUDPPorts = [
        53 # DNS
        67 # DHCP
      ];
    };
  };

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
