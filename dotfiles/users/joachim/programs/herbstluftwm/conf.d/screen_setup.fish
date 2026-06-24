#! /usr/bin/env fish

function hc
    herbstclient $argv
end

# Screen setup
autorandr --change
set -l current_profile (autorandr --detected | head -1)
switch $current_profile
    case "Work*"
        hc and , \
            set_monitors 1120x2160+0+0 1600x2160+1120+0 1120x2160+2720+0 , \
            rename_monitor 0 left , \
            rename_monitor 1 main , \
            rename_monitor 2 right
    case Gaming_4K
        hc and , \
            set_monitors 3840x2160+0+0 , \
            rename_monitor 0 main
    case Gaming_1080p
        hc and , \
            set_monitors 1920x1080+0+0 , \
            rename_monitor 0 main
end

# Remove the leftover "default" tag now that set_monitors has pointed every
# monitor at a named tag (it can't be removed while still displayed). try keeps
# RandR re-runs quiet once it's already gone.
hc silent try merge_tag default left_lower

# Launch polybar. No POLYBAR_WIDTH/POLYBAR_OFFSET_X set, so config.ini falls
# back to the triple-head center-monitor defaults.
polybar-msg cmd quit 2>/dev/null
for i in (seq 20)
    pgrep -x polybar >/dev/null 2>&1; or break
    sleep 0.1
end
polybar bar >/dev/null 2>&1 &
disown
