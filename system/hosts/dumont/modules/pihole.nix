{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  # Public domains that must never be blocked, one per line. Not secret, so
  # they live in the repo; comments and blank lines are ignored.
  allowlistFile = ./pihole-allowlist.txt;
  hasAllowlist =
    builtins.any (l: l != "" && !(lib.hasPrefix "#" l))
    (lib.splitString "\n" (builtins.readFile allowlistFile));
in {
  # ============================================================================
  # Pi-hole v6 (native NixOS modules)
  # ============================================================================
  # Everything in `settings` is rendered into a world-readable store file and
  # so ends up public. The device inventory (DHCP reservations with MACs,
  # local DNS records) and the web password therefore come from sops at
  # runtime; see openspec/changes/add-dumont-pihole-host/design.md (D7).
  #
  # misc.readOnly (module default) keeps the web UI/API from changing the
  # configuration: a redeploy always restores what is declared here.

  services.pihole-ftl = {
    enable = true;

    settings = {
      dns = {
        # Quad9, same as wintermute's PIHOLE_DNS_1..4
        upstreams = ["9.9.9.9" "149.112.112.112" "2620:fe::fe" "2620:fe::9"];
        dnssec = true;
        # Answer only clients on directly attached subnets (LAN, ULA, GUA)
        listeningMode = "LOCAL";
        domain = {
          name = "meine2cent.home";
          # Never forward the LAN domain upstream
          local = true;
        };
        expandHosts = true;
        domainNeeded = true;
        bogusPriv = true;
      };

      dhcp = {
        # Off until the cutover (Migration Plan, phase 3); flipping this is
        # the DHCP handover. When on, FTL also writes dhcp-authoritative.
        active = false;
        # Same range as wintermute's DHCP_START/DHCP_END (read 2026-10-18);
        # .2 (dumont) and .3 (wintermute) stay outside it
        start = "192.168.1.12";
        end = "192.168.1.254";
        router = "192.168.1.1";
        netmask = "255.255.255.0";
        leaseTime = "24h";
        # No DHCPv6 and no router advertisements: the Speedport sends RAs
        ipv6 = false;
      };

      # Query history is the main writer on the eMMC; keep it short
      database.maxDBdays = 30;

      misc = {
        readOnly = true;
        # Device inventory from sops (only its path is public)
        dnsmasq_lines = [
          "conf-file=${config.sops.secrets.pihole_inventory.path}"
        ];
      };
    };

    lists =
      [
        {
          url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
          description = "StevenBlack unified hosts";
        }
        {
          # raw.githubusercontent.com works from the LAN; HaGeZi's jsdelivr
          # mirror returned 403 from wintermute
          url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt";
          description = "HaGeZi Multi PRO";
        }
      ]
      ++ lib.optional hasAllowlist {
        url = "file://${allowlistFile}";
        type = "allow";
        description = "Local allowlist (repo)";
      };
  };

  services.pihole-web = {
    enable = true;
    hostName = "dumont.meine2cent.home";
    ports = ["80"];
  };

  sops = {
    # Raw dnsmasq lines: dhcp-host=<mac>,<ip>,<name> reservations and
    # host-record=<name>,<ip> local names
    secrets.pihole_inventory = {
      owner = config.services.pihole-ftl.user;
      restartUnits = ["pihole-ftl.service"];
    };
    secrets.pihole_web_password = {};
    templates."pihole-web.env" = {
      owner = config.services.pihole-ftl.user;
      content = ''
        FTLCONF_webserver_api_password=${config.sops.placeholder.pihole_web_password}
      '';
      restartUnits = ["pihole-ftl.service"];
    };
  };

  systemd.services = {
    # FTL hashes the password into its in-memory config at startup; the
    # plaintext only exists in the sops-rendered file under /run
    pihole-ftl.serviceConfig.EnvironmentFile =
      config.sops.templates."pihole-web.env".path;

    pihole-ftl-setup = {
      # The module's setup service runs `pihole -g` after adding the lists, but
      # only signals FTL on the very first run (empty database). Gravity swaps in
      # a new gravity.db and FTL keeps serving the old one until SIGRTMIN, so
      # blocking stayed off after install. Same user as FTL, so kill is allowed.
      # Stay "active (exited)" after a successful run. switch-to-configuration
      # only restarts changed units that are active, so without this a deploy
      # that changes the lists never re-runs the setup.
      serviceConfig.RemainAfterExit = true;

      serviceConfig.ExecStartPost = pkgs.writeShellScript "pihole-reload-lists" ''
        ${lib.getExe' pkgs.procps "kill"} -s SIGRTMIN \
          "$(${lib.getExe' config.systemd.package "systemctl"} show --property MainPID --value pihole-ftl.service)"
      '';

      # 26.05's setup script exits 1 on every run after the first: re-adding a
      # list that is already in gravity.db is a database_error. nixos-unstable
      # treats "already present" as success; use its script until 26.05 has it.
      # TODO(26.11): drop this override.
      script = lib.mkForce (
        import "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/pihole-ftl-setup-script.nix" {
          cfg = config.services.pihole-ftl;
          inherit config lib pkgs;
        }
      );
    };
  };
}
