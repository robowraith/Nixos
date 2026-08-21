#! /usr/bin/env fish

# Toggle between an urgent window and the window you were working in:
#   - if any window is urgent, remember the current one and jump to it
#   - otherwise jump back to the remembered window
#
# HerbstluftWM clears urgency as soon as a window is focused, so pressing the
# key a second time takes you back.

set -l state_dir (test -n "$XDG_RUNTIME_DIR" && echo $XDG_RUNTIME_DIR || echo /tmp)
set -l state_file $state_dir/herbstluftwm-jump-back

set -l current (herbstclient attr clients.focus.winid 2>/dev/null)

if herbstclient jumpto urgent 2>/dev/null
    # Jumped to the urgent window - remember where we came from.
    if test -n "$current"
        echo $current >$state_file
    end
else
    # Nothing is urgent - go back, if the remembered window still exists.
    if test -f $state_file
        set -l previous (cat $state_file)
        if test -n "$previous"; and herbstclient attr clients.$previous >/dev/null 2>&1
            herbstclient jumpto $previous
        end
        rm -f $state_file
    end
end
