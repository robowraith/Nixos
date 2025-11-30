#! /usr/bin/env fish

# Script to switch to tag $argv[2] on monitor $argv[1]

function hc
    herbstclient $argv
end

set target_monitor $argv[1]
set target_tag $argv[2]

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
