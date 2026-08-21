#!/usr/bin/env bash
#
# Regression test for the ssh-tunnel-* keepalive settings.
#
# Drops outbound port 22 to the tunnel's peer, forcing the exact half-open TCP
# state that used to hang forever: before ServerAliveInterval was set, ssh kept
# running around a dead connection, so systemd reported the unit as "running"
# while the forward was gone. A passing run proves ssh notices, exits, and gets
# restarted with a working forward.
#
# Usage: ./keepalive-test.sh [dc1|ac4]      (default: dc1)
#
# Two traps for the unwary, both learned the hard way:
#   - The peer is read from the live socket, never resolved by name. The cluster
#     hosts have both A and AAAA records and the tunnels actually use IPv6, so
#     blocking the IPv4 address matches nothing and the test silently "fails"
#     while the config is fine. The rule's packet counter is printed so a
#     zero-match run is recognisable as an invalid test rather than a real FAIL.
#   - MainPID becomes 0 during the RestartSec window. Treating "pid changed" as
#     success reports a pass before the replacement ssh exists, so recovery is
#     confirmed separately, by probing the forwarded port.
#
# The DROP rule is removed by the trap on every exit path, including Ctrl-C.
set -u

HOST=${1:-dc1}
UNIT="ssh-tunnel-${HOST}"

prop() { systemctl --user show "$UNIT" -p "$1" --value; }

PID_BEFORE=$(prop MainPID)
[ "$PID_BEFORE" = "0" ] && {
  echo "$UNIT is not running (MainPID=0)"
  exit 1
}

# Local forward port, straight from the running process: "-L 64431:localhost:6443".
LPORT=$(tr '\0' '\n' <"/proc/$PID_BEFORE/cmdline" | grep -oP '^\d+(?=:localhost:)')
[ -z "$LPORT" ] && {
  echo "could not determine the forwarded port from pid $PID_BEFORE"
  exit 1
}

# Field 5 of `ss -tnpH` is the peer: "1.2.3.4:22" or "[2a01:...::2]:22".
PEER=$(ss -tnpH 2>/dev/null | awk -v p="pid=$PID_BEFORE," '$0 ~ p {print $5; exit}')
[ -z "$PEER" ] && {
  echo "no established connection for pid $PID_BEFORE"
  exit 1
}

if [[ $PEER == \[* ]]; then
  IP=${PEER#[}
  IP=${IP%%]*}
  IPT=ip6tables
  FAM=IPv6
else
  IP=${PEER%:*}
  IPT=iptables
  FAM=IPv4
fi

RULE=(OUTPUT -d "$IP" -p tcp --dport 22 -j DROP)

cleanup() {
  echo "--- rule counters (packets MUST be > 0, or the test was invalid):"
  sudo "$IPT" -vnL OUTPUT 2>/dev/null | grep -- "$IP" || echo "  rule not found"
  sudo "$IPT" -D "${RULE[@]}" 2>/dev/null
  sudo "$IPT" -C "${RULE[@]}" 2>/dev/null &&
    echo "!!! WARNING: rule still present, remove it manually" ||
    echo "verified: no leftover rule"
}
trap cleanup EXIT

probe() { curl -sk --max-time 5 -o /dev/null "https://127.0.0.1:${LPORT}/version"; }

echo "$UNIT: pid=$PID_BEFORE peer=$PEER ($FAM, $IPT) port=$LPORT NRestarts=$(prop NRestarts)"
probe && echo "baseline: forward on $LPORT answers" ||
  echo "baseline: forward on $LPORT already broken - fix that before testing"

sudo "$IPT" -I "${RULE[@]}" || exit 1
echo "--- outbound :22 to $IP dropped; ssh should exit in ~20s"

START=$SECONDS
DETECTED=""
RECOVERED=""

# Phase 1: ssh must exit. Phase 2: a NEW non-zero MainPID must serve the
# forward again. Both inside one window - the rule stays up throughout, so
# recovery is proven against an active DROP for the old connection only.
while [ $((SECONDS - START)) -lt 90 ]; do
  PID_NOW=$(prop MainPID)

  if [ -z "$DETECTED" ] && [ "$PID_NOW" != "$PID_BEFORE" ]; then
    DETECTED=$((SECONDS - START))
    echo "  [${DETECTED}s] ssh exited"
  fi

  if [ -n "$DETECTED" ] && [ "$PID_NOW" != "0" ] && [ "$PID_NOW" != "$PID_BEFORE" ]; then
    if [ "$(prop ActiveState)" = "active" ] && probe; then
      RECOVERED=$((SECONDS - START))
      echo "  [${RECOVERED}s] forward on $LPORT answers again (new pid=$PID_NOW)"
      break
    fi
  fi

  sleep 1
done

echo
if [ -n "$RECOVERED" ]; then
  echo "*** PASS: detected in ${DETECTED}s, tunnel working again after ${RECOVERED}s"
elif [ -n "$DETECTED" ]; then
  echo "*** PARTIAL: ssh exited after ${DETECTED}s but the forward never came back."
  echo "    Detection works; recovery does not. Check for a stale process on $LPORT:"
  ss -ltnp 2>/dev/null | grep ":$LPORT" || echo "    (nothing listening)"
else
  echo "*** FAIL: ssh still alive on pid $PID_BEFORE after $((SECONDS - START))s."
  echo "    Check the packet counters below: 0 means the test never reached the"
  echo "    connection and the keepalive was not actually exercised."
fi

echo "NRestarts: $(prop NRestarts)"
echo "--- ssh-side journal:"
journalctl --user -u "$UNIT" --since "-3min" --no-pager | grep -vE "systemd\[" | tail -8
