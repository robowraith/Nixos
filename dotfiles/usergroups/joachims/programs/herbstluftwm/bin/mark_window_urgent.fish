#! /usr/bin/env fish

# Mark the terminal window this script is called from as urgent in HerbstluftWM
# so its border turns red (theme.urgent). Used by the Claude Code hooks in
# ~/.claude/settings.json: set on notification, cleared on prompt submit.
#
# Usage: mark_window_urgent.fish [on|off]   (default: on)

set -l state true
if test (count $argv) -gt 0; and test "$argv[1]" = off
    set state false
end

# WINDOWID is exported by the terminal emulator (kitty, xterm, ...)
if not string match -qr '^[0-9]+$' -- "$WINDOWID"
    exit 0
end
type -q herbstclient; or exit 0

set -l winid (printf '0x%x' $WINDOWID)

# herbstluftwm resets urgency on the focused client, so setting it is a no-op
# while the window has focus.
herbstclient set_attr clients.$winid.urgent $state 2>/dev/null

exit 0
