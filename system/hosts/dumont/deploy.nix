# Guarded deploy for dumont (design.md D8), exposed as `nix run .#deploy-dumont`.
#
# Builds dumont's system here, copies it over, activates it with `test`, and
# health-checks DNS from this machine. Only if every check passes does the
# generation become the boot default; otherwise the previous generation is
# re-activated and the command exits 1. A power cycle therefore always boots
# the last good generation.
#
# Everything addresses dumont by IP, so deploy and rollback work while LAN
# DNS is down.
{
  pkgs,
  toplevel,
}: let
  host = "192.168.1.2";
  user = "yori";
  # Pin dumont's host key (the private half is in secrets/dumont.yaml)
  knownHosts = pkgs.writeText "dumont-known-hosts" "${host} ${builtins.readFile ./ssh_host_ed25519_key.pub}";
in
  pkgs.writeShellApplication {
    name = "deploy-dumont";
    runtimeInputs = with pkgs; [openssh dnsutils coreutils];
    text = ''
      usage() {
        cat <<USAGE
      Usage: deploy-dumont [--help]

      Deploy this flake's dumont configuration to ${user}@${host}:
        1. copy ${toplevel}
        2. activate it with switch-to-configuration test
        3. health checks from here, retried for ~30 s:
             dig @${host} example.com    returns an address
             dig @${host} doubleclick.net returns 0.0.0.0
             ssh ${user}@${host} true
             pihole-ftl.service is active
             pihole-ftl-setup.service has not failed
        4. all pass: make it the boot default
           any fail: re-activate the previous generation, exit 1

      Asks for ${user}'s sudo password first and checks it. Run it from the flake root:
        nix run .#deploy-dumont
      USAGE
      }

      case "''${1:-}" in
        -h | --help) usage; exit 0 ;;
        "") ;;
        *) usage >&2; exit 2 ;;
      esac

      new=${toplevel}
      target=${user}@${host}
      sshOpts=(-o UserKnownHostsFile=${knownHosts} -o StrictHostKeyChecking=yes -o ConnectTimeout=5)
      export NIX_SSHOPTS="''${sshOpts[*]}"

      # Arguments are meant to expand here and run as one remote command line
      # shellcheck disable=SC2029
      # -n: never let ssh read the terminal (it would swallow typed input)
      rssh() { ssh -n "''${sshOpts[@]}" "$target" "$@"; }
      # Run as root on dumont, feeding the password read below to sudo
      # shellcheck disable=SC2029
      rsudo() { ssh "''${sshOpts[@]}" "$target" "sudo -S -p ''' $*" <<<"$password"; }
      # Activation restarts networkd and may drop the SSH session; run it as a
      # transient unit so it finishes regardless (as nixos-rebuild does)
      activate() {
        rsudo systemd-run --collect --pipe --quiet --service-type=exec \
          --unit="deploy-dumont-$2-$RANDOM" "$1/bin/switch-to-configuration" "$2"
      }

      # Ask first, before anything slow, and check it right away
      for attempt in 1 2 3; do
        IFS= read -rsp "[sudo] password for ${user}@${host}: " password </dev/tty
        echo
        rsudo -k true 2>/dev/null && break
        echo "sudo refused the password (''${#password} characters read)" >&2
        [[ $attempt -lt 3 ]] || exit 1
      done

      prev=$(rssh readlink -f /run/current-system)
      echo "current: $prev"
      echo "new:     $new"

      echo "==> copying closure"
      # Locally built paths are unsigned; nix copy still asks the remote to check
      # signatures unless told not to. Only honoured because yori is trusted
      # (server hostgroup, remote-deploy.nix).
      nix copy --no-check-sigs --substitute-on-destination --to "ssh-ng://$target" "$new"

      revert() {
        echo "==> FAILED: $1; re-activating $prev" >&2
        activate "$prev" test || echo "revert failed: run '$prev/bin/switch-to-configuration test' on dumont" >&2
        exit 1
      }

      # Only failures caused by this activation should count in the checks
      rsudo systemctl reset-failed pihole-ftl-setup.service || true

      echo "==> activating (test)"
      rc=0
      activate "$new" test || rc=$?
      # 255 is ssh itself (session dropped by the networkd restart); the unit
      # keeps running on dumont, so let the health checks decide
      if [[ $rc -eq 255 ]]; then
        echo "SSH session dropped during activation; continuing with health checks"
      elif [[ $rc -ne 0 ]]; then
        revert "switch-to-configuration test (exit $rc)"
      fi

      check() {
        failed=""
        # dig +short prints errors such as timeouts to stdout as well, so
        # require an actual address
        [[ "$(dig +short +time=2 +tries=1 @${host} example.com A)" =~ (^|$'\n')[0-9]+(\.[0-9]+){3}($|$'\n') ]] || failed+=" dns"
        [[ "$(dig +short +time=2 +tries=1 @${host} doubleclick.net A)" == "0.0.0.0" ]] || failed+=" blocking"
        rssh true 2>/dev/null || failed+=" ssh"
        rssh systemctl is-active --quiet pihole-ftl.service 2>/dev/null || failed+=" pihole-ftl"
        ! rssh systemctl is-failed --quiet pihole-ftl-setup.service 2>/dev/null || failed+=" pihole-ftl-setup"
        [[ -z "$failed" ]]
      }

      echo "==> health checks"
      for _ in $(seq 10); do
        check && break
        sleep 3
      done
      [[ -z "$failed" ]] || revert "health check:$failed"
      echo "all checks passed"

      echo "==> making it the boot default"
      rsudo nix-env -p /nix/var/nix/profiles/system --set "$new"
      activate "$new" boot
      echo "deployed $new"
    '';
  }
