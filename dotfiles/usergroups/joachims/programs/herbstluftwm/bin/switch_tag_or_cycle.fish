#! /usr/bin/env fish

# Script to switch to tag $argv[2] on monitor $argv[1]

function hc
    herbstclient $argv
end

set target_monitor $argv[1]
set target_tag $argv[2]

set profile (autorandr --detected 2>/dev/null | head -1)

# In two-screen setups the office monitor names (left/main/right) don't
# exist. Route tags to the two physical monitors instead.
if test "$profile" = Notebook_USBC
    # lower group (keys 1-5) -> main (0), everything else -> up (1).
    switch $target_tag
        case left_lower main_lower right_lower left_main main_main
            set target_monitor main
        case '*'
            set target_monitor up
    end
else if test "$profile" = Work_Cellar
    # keys 0-5 -> main (HDMI-1), keys 6-9 -> side (eDP-1).
    switch $target_tag
        case fullscreen left_lower main_lower right_lower left_main main_main
            set target_monitor main
        case '*'
            set target_monitor side
    end
end

if test (hc attr monitors.focus.name) = $target_monitor
    if test (hc attr tags.focus.name) = $target_tag
        hc cycle +1
    else
        hc use $target_tag
    end
else
    hc chain , \
        focus_monitor $target_monitor , \
        use $target_tag
end

exit 0
