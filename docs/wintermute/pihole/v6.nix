# Pi-hole v6 on wintermute's k3s, rendered from dumont's evaluated config
# (task 8.7/8.8 of openspec/changes/add-dumont-pihole-host).
#
# `nix build .#wintermute-pihole` produces a Kubernetes List (JSON) to
# `kubectl apply`. Every FTL setting comes from
# nixosConfigurations.dumont.config.services.pihole-ftl, so wintermute's
# standby cannot drift from dumont: the only intended differences are
# `dhcp.active` (off, the cold standby of design D11), `dhcp.leaseTime` (1 h)
# and what only makes sense on one host (file paths, web port and name).
#
# The settings go in as FTLCONF_* environment variables. FTL applies them on
# every start and refuses changes to them via the web UI or `--config`, so a
# re-apply always restores the repo state.
#
# Not in here, because the repo is public:
# - the device inventory: Secret `pihole-inventory`, made from
#   secrets/dumont.yaml at apply time (README → Pi-hole v6)
# - the web password: the existing Secret `pihole-web-password`
{
  pkgs,
  lib,
  dumont,
}: let
  ftl = dumont.services.pihole-ftl;

  # 2026.11.0 ships FTL 6.9 / Core 6.6. Check `pihole -v` in the pod.
  image = "pihole/pihole:2026.11.0";
  namespace = "pihole";
  webHost = "pihole.meine2cent.internal";
  # Pre-.internal name; the cluster's Ingress still has it, keep it until
  # the .home cleanup (HANDOFF, LAN domain)
  oldWebHost = "pihole.meine2cent.home";
  # Traefik's ServiceLB owns :80/:443 on the host; v6's built-in webserver
  # would otherwise try both and leave the pod Pending
  webPort = "8080";

  # Fresh state directory on purpose: the v6 image migrates a v5
  # /etc/pihole it finds, and v5 must stay intact for the rollback.
  stateDir = "/etc/pihole-v6";
  inventoryDir = "/etc/pihole-inventory";
  listsDir = "/etc/pihole-lists";

  # --- FTL settings -----------------------------------------------------------

  dumontInventoryLine = "conf-file=${dumont.sops.secrets.pihole_inventory.path}";
  dnsmasqLines = assert lib.assertMsg
  (builtins.elem dumontInventoryLine ftl.settings.misc.dnsmasq_lines)
  "wintermute-pihole: dumont no longer loads its inventory via `${dumontInventoryLine}`";
    map (l:
      if l == dumontInventoryLine
      then "conf-file=${inventoryDir}/inventory.conf"
      else l)
    ftl.settings.misc.dnsmasq_lines
    ++ [
      # hostNetwork pods get the node's /etc/hosts, and wintermute's still
      # lists old aliases (`deepthought`), which expand-hosts turned into
      # deepthought.meine2cent.internal → .3 (seen 2026-11-24). Every LAN
      # name comes from the inventory instead.
      "no-hosts"
      # dumont answers its own name from its hostname (not the inventory),
      # so the standby needs it spelled out
      "host-record=${dumont.networking.hostName}.${ftl.settings.dns.domain.name},${dumontAddress}"
    ];
  dumontAddress = let
    addrs = dumont.systemd.network.networks."10-lan".address;
  in
    assert lib.assertMsg (builtins.length addrs == 1)
    "wintermute-pihole: expected exactly one static address on dumont's 10-lan";
      lib.head (lib.splitString "/" (lib.head addrs));

  settings =
    lib.recursiveUpdate
    (removeAttrs ftl.settings ["files"]
      // {
        # NixOS-only paths (store webroot, /var/lib/pihole cert); the image
        # has its own
        webserver = removeAttrs ftl.settings.webserver ["paths" "tls" "domain"];
        # readOnly would also block the image's entrypoint from writing its
        # own keys; the FTLCONF_* variables lock every key set here anyway
        misc = removeAttrs ftl.settings.misc ["readOnly"];
      })
    {
      dhcp = {
        active = false;
        leaseTime = "1h";
      };
      webserver = {
        port = webPort;
        domain = webHost;
      };
      misc.dnsmasq_lines = dnsmasqLines;
    };

  # FTLCONF_<section>_<key>; arrays are semicolon-separated
  render = v:
    if builtins.isBool v
    then lib.boolToString v
    else if builtins.isList v
    then
      assert lib.assertMsg (builtins.all (e: !(lib.hasInfix ";" (toString e))) v)
      "wintermute-pihole: array element contains ';'";
        lib.concatStringsSep ";" (map toString v)
    else toString v;
  toEnv = prefix: v:
    if builtins.isAttrs v
    then lib.concatLists (lib.mapAttrsToList (k: toEnv "${prefix}_${k}") v)
    else [
      {
        name = prefix;
        value = render v;
      }
    ];
  ftlEnv = toEnv "FTLCONF" settings;

  # --- Gravity lists ----------------------------------------------------------
  # Adlists live in gravity.db, not in the config, so they are seeded by a
  # script (ConfigMap `pihole-lists`) that is run once after the first start
  # and again whenever the lists change. Like dumont's setup, it only adds.

  isFile = l: lib.hasPrefix "file://" l.url;
  # /nix/store/<hash>-name → name
  fileKey = l: let
    base = builtins.unsafeDiscardStringContext (baseNameOf l.url);
  in
    builtins.substring 33 (-1) base;
  listUrl = l:
    if isFile l
    then "file://${listsDir}/${fileKey l}"
    else l.url;
  sqlQuote = s: "'${lib.replaceStrings ["'"] ["''"] s}'";
  typeOf = l:
    {
      block = "0";
      allow = "1";
    }
    .${
      l.type
    };
  enabledOf = l:
    if l.enabled
    then "1"
    else "0";

  syncLists = ''
    #!/bin/sh
    # Generated by docs/wintermute/pihole/v6.nix from dumont's
    # services.pihole-ftl.lists. Adds missing lists, then rebuilds gravity.
    set -eu
    db=/etc/pihole/gravity.db
    ${lib.concatMapStrings (l: ''
        pihole-FTL sqlite3 "$db" "INSERT OR IGNORE INTO adlist (address, enabled, comment, type) VALUES (${
          lib.concatStringsSep ", " [(sqlQuote (listUrl l)) (enabledOf l) (sqlQuote l.description) (typeOf l)]
        });"
      '')
      ftl.lists}
    pihole -g
  '';

  listsConfigMap = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "pihole-lists";
      inherit namespace;
    };
    data =
      {"sync-lists.sh" = syncLists;}
      // lib.listToAttrs (map (l: {
        name = fileKey l;
        value = builtins.readFile (lib.removePrefix "file://" l.url);
      }) (builtins.filter isFile ftl.lists));
  };

  # --- Workload ---------------------------------------------------------------

  deployment = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "pihole-deployment";
      inherit namespace;
      labels.app = "pihole";
    };
    spec = {
      replicas = 1;
      selector.matchLabels.app = "pihole";
      # hostNetwork: old and new pod cannot both hold :53
      strategy.type = "Recreate";
      template = {
        metadata.labels.app = "pihole";
        spec = {
          hostNetwork = true;
          dnsPolicy = "ClusterFirstWithHostNet";
          containers = [
            {
              name = "pihole";
              inherit image;
              imagePullPolicy = "IfNotPresent";
              env =
                [
                  {
                    name = "TZ";
                    value = dumont.time.timeZone;
                  }
                  {
                    name = "FTLCONF_webserver_api_password";
                    valueFrom.secretKeyRef = {
                      name = "pihole-web-password";
                      key = "WEBPASSWORD";
                    };
                  }
                ]
                ++ ftlEnv;
              ports = [
                {
                  containerPort = 53;
                  protocol = "UDP";
                }
                {
                  containerPort = 53;
                  protocol = "TCP";
                }
                {
                  containerPort = 67;
                  protocol = "UDP";
                }
                {
                  containerPort = lib.toInt webPort;
                  protocol = "TCP";
                }
              ];
              resources = {
                limits = {
                  cpu = "2";
                  memory = "2Gi";
                };
                requests = {
                  cpu = "250m";
                  memory = "256Mi";
                };
              };
              securityContext.capabilities.add = ["NET_ADMIN" "NET_RAW" "NET_BIND_SERVICE" "SYS_NICE"];
              volumeMounts = [
                {
                  name = "pihole-state";
                  mountPath = "/etc/pihole";
                }
                {
                  name = "pihole-inventory";
                  mountPath = inventoryDir;
                  readOnly = true;
                }
                {
                  name = "pihole-lists";
                  mountPath = listsDir;
                  readOnly = true;
                }
              ];
            }
          ];
          volumes = [
            {
              name = "pihole-state";
              hostPath = {
                path = stateDir;
                type = "DirectoryOrCreate";
              };
            }
            {
              name = "pihole-inventory";
              secret.secretName = "pihole-inventory";
            }
            {
              name = "pihole-lists";
              configMap.name = "pihole-lists";
            }
          ];
        };
      };
    };
  };

  # --- Web (unchanged from the v5 manifest, plus /api for the v6 UI) -----------

  service = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "pihole-web";
      inherit namespace;
      labels.app = "pihole";
    };
    spec = {
      type = "ClusterIP";
      selector.app = "pihole";
      ports = [
        {
          name = "pihole-http";
          port = 80;
          protocol = "TCP";
          targetPort = lib.toInt webPort;
        }
      ];
    };
  };

  ingressRule = host: {
    inherit host;
    http.paths = map (path: {
      inherit path;
      pathType = "Prefix";
      backend.service = {
        name = "pihole-web";
        port.name = "pihole-http";
      };
    }) ["/admin" "/api"];
  };

  ingress = {
    apiVersion = "networking.k8s.io/v1";
    kind = "Ingress";
    metadata = {
      name = "pihole-ingress";
      inherit namespace;
      labels.app = "pihole";
    };
    spec = {
      ingressClassName = "traefik";
      rules = map ingressRule [webHost oldWebHost];
    };
  };

  rootRoute = {
    apiVersion = "traefik.containo.us/v1alpha1";
    kind = "IngressRoute";
    metadata = {
      name = "pihole-root";
      inherit namespace;
    };
    spec = {
      entryPoints = ["web"];
      routes = [
        {
          kind = "Rule";
          match = "Host(`${webHost}`) && Path(`/`)";
          middlewares = [{name = "pihole-redirect-to-admin";}];
          services = [
            {
              name = "pihole-web";
              port = 80;
            }
          ];
        }
      ];
    };
  };

  redirectMiddleware = {
    apiVersion = "traefik.containo.us/v1alpha1";
    kind = "Middleware";
    metadata = {
      name = "pihole-redirect-to-admin";
      inherit namespace;
    };
    spec.redirectRegex = {
      permanent = false;
      regex = "^http://${lib.replaceStrings ["."] ["\\."] webHost}/?$";
      replacement = "http://${webHost}/admin/";
    };
  };
in
  pkgs.writeText "wintermute-pihole.json" (builtins.toJSON {
    apiVersion = "v1";
    kind = "List";
    items = [listsConfigMap deployment service ingress rootRoute redirectMiddleware];
  })
