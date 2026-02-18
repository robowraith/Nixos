{
  hostname,
  pkgs,
  ...
}: {
  # ============================================================================
  # Networking
  # ============================================================================

  networking = {
    hostName = hostname;

    # Static IP configuration
    # Note: Adjust the interface name based on your hardware
    # Use `ip link` to find your actual interface name
    interfaces.enp7s0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.1.";
          prefixLength = 24;
        }
      ];
    };

    # Firewall
    firewall.allowedTCPPorts = [];

    networkmanager.dispatcherScripts = [
      {
        source = let
          nmcli = "${pkgs.networkmanager}/bin/nmcli";
        in
          pkgs.writeShellScript "wifi-wired-exclusive" ''
            IFACE=$1
            ACTION=$2

            case "$IFACE" in
              en*|eth*)
                case "$ACTION" in
                  up)
                    ${nmcli} radio wifi off
                    ;;
                  down)
                    if ! ${nmcli} -t -f DEVICE,STATE device status | grep -Eq "^(en|eth).*connected$"; then
                      ${nmcli} radio wifi on
                    fi
                    ;;
                esac
                ;;
            esac
          '';
      }
    ];

    extraHosts = ''
      192.168.56.20 ac1.local
      192.168.56.21 ac2.local
      192.168.56.22 ac3.local
      192.168.56.23 ac4.local
      192.168.56.24 ass.local
      192.168.56.25 db1.local
      192.168.56.26 db2.local
      192.168.56.27 dba.local
      192.168.56.28 dbb.local
      192.168.56.29 dbc.local
      192.168.56.30 dc1.local
      192.168.56.31 dc2.local
      192.168.56.32 dc3.local
      192.168.56.33 dev1.local
      192.168.56.34 gr1.local
      192.168.56.37 sx1.local
      192.168.56.38 ws1.local
      192.168.56.39 ws2.local
      192.168.56.40 ws9.local
      192.168.56.41 jolly1.local
    '';
  };
}
