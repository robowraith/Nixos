#! /usr/bin/env fish

function hc
    herbstclient $argv
end

# Script to set up tag layouts.
# Default frame layout: side-by-side (horizontal) on the notebook setups
# (Notebook_USBC, Notebook_1200), stacked (vertical) everywhere else. This must
# run before the tags are added below: default_frame_layout only affects frames
# created afterwards, it does not retroactively relayout existing tag frames.
switch (autorandr --detected 2>/dev/null | head -1)
    case Notebook_USBC Notebook_1200
        hc set default_frame_layout horizontal
    case '*'
        hc set default_frame_layout vertical
end

# Establish tags
hc and , \
    try add 0 , \
    rename 0 fullscreen , \
    new_attr string tags.0.my_monitor , \
    set_attr tags.0.my_monitor fullscreen

hc and , \
    add 1 , \
    rename 1 left_lower , \
    new_attr string tags.1.my_monitor , \
    set_attr tags.1.my_monitor left

hc and , \
    add 2 , \
    rename 2 main_lower , \
    new_attr string tags.3.my_monitor , \
    set_attr tags.2.my_monitor main

hc and , \
    add 3 , \
    rename 3 right_lower , \
    new_attr string tags.3.my_monitor , \
    set_attr tags.3.my_monitor right

hc and , \
    add 4 , \
    rename 4 left_main , \
    new_attr string tags.4.my_monitor , \
    set_attr tags.4.my_monitor left

hc and , \
    add 5 , \
    rename 5 main_main , \
    new_attr string tags.6.my_monitor , \
    set_attr tags.6.my_monitor main

hc and , \
    add 6 , \
    rename 6 right_main , \
    new_attr string tags.6.my_monitor , \
    set_attr tags.6.my_monitor right

hc and , \
    add 7 , \
    rename 7 left_upper , \
    new_attr string tags.7.my_monitor , \
    set_attr tags.7.my_monitor left

hc and , \
    add 8 , \
    rename 8 main_upper , \
    new_attr string tags.8.my_monitor , \
    set_attr tags.8.my_monitor main

hc and , \
    add 9 , \
    rename 9 right_upper , \
    new_attr string tags.9.my_monitor , \
    set_attr tags.9.my_monitor right

# NOTE: the leftover "default" tag is removed in screen_setup.fish, after
# set_monitors has pointed every monitor at a named tag. herbstluftwm refuses
# to remove a tag that is currently displayed on a monitor, and at this point
# "default" is still the viewed tag, so merging here would silently fail.

exit 0
