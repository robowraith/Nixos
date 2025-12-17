#! /usr/bin/env fish

# This script will move a window to a new fullscreen monitor and back

function hc
    herbstclient $argv
end

set original_tag (hc attr tags.focus.name)
set original_monitor (hc attr monitors.focus.name)
set fullscreen_monitor_name fullscreen
set fullscreen_tag_name fullscreen

# Add tag for new monitor
hc silent try add $fullscreen_tag_name
hc silent try new_attr string tags.by-name.$fullscreen_tag_name.my_original_tag
hc silent try new_attr string tags.by-name.$fullscreen_tag_name.my_original_monitor

if hc add_monitor 3840x2160+0+000 $fullscreen_tag_name $fullscreen_monitor_name
    hc attr tags.by-name.$fullscreen_tag_name.my_original_tag $original_tag
    hc attr tags.by-name.$fullscreen_tag_name.my_original_monitor $original_monitor
    hc and , \
        move $fullscreen_tag_name , \
        focus_monitor $fullscreen_monitor_name , \
        fullscreen on
    exit 0
else
    set -l original_tag (hc attr tags.by-name.$fullscreen_tag_name.my_original_tag)
    set -l original_monitor (hc attr tags.by-name.$fullscreen_tag_name.my_original_monitor)
    hc and , \
        focus_monitor $fullscreen_monitor_name , \
        fullscreen off , \
        move $original_tag , \
        focus_monitor $original_monitor , \
        remove_monitor $fullscreen_monitor_name
    exit 0
end

exit 1
