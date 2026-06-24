#! /usr/bin/env fish

function hc
    herbstclient $argv
end

# (Re)launch polybar, picking up the POLYBAR_WIDTH/POLYBAR_OFFSET_X env vars
# set per profile below. Runs on every autostart pass (incl. RandR re-runs),
# so kill any existing bars first to avoid duplicates.
function launch_polybar
    polybar-msg cmd quit 2>/dev/null
    for i in (seq 20)
        pgrep -x polybar >/dev/null 2>&1; or break
        sleep 0.1
    end
    polybar bar >/dev/null 2>&1 &
    disown
end

# Screen setup
autorandr --change

# At login the outputs may not be settled yet, so autorandr --detected can
# return nothing and no case below would match (leaving HLWM on its stale
# default monitor). Poll until a profile is detected before laying out.
set -l current_profile ""
for i in (seq 50)
    set current_profile (autorandr --detected | head -1)
    test -n "$current_profile"; and break
    sleep 0.1
end

# Default polybar geometry (triple-head center monitor); Notebook_* overrides
# below make the bar span the whole screen.
set -e POLYBAR_WIDTH
set -e POLYBAR_OFFSET_X

switch $current_profile
    case "Work*"
        hc and , \
            set_monitors 1120x2160+0+0 1600x2160+1120+0 1120x2160+2720+0 , \
            rename_monitor 0 left , \
            rename_monitor 1 main , \
            rename_monitor 2 right

    case Gaming_1080p
        hc and , \
            set_monitors 1920x1080+0+0 , \
            rename_monitor 0 main

    case Gaming_4K
        hc and , \
            set_monitors 3840x2160+0+0 , \
            rename_monitor 0 main

    case Notebook_1200
        set -gx POLYBAR_WIDTH 100%
        set -gx POLYBAR_OFFSET_X 0
        hc and , \
            set_monitors 1920x1200+0+0 , \
            rename_monitor 0 main

    case Notebook_USBC
        set -gx POLYBAR_WIDTH 100%
        set -gx POLYBAR_OFFSET_X 0
        hc and , \
            set_monitors 1920x1200+0+1200 1920x1200+0+0 , \
            rename_monitor 0 main , \
            rename_monitor 1 up
end

# Remove the leftover "default" tag now that set_monitors has pointed every
# monitor at a named tag (it can't be removed while still displayed). try keeps
# RandR re-runs quiet once it's already gone.
hc silent try merge_tag default left_lower

launch_polybar
