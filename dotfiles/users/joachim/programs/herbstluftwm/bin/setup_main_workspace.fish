#! /usr/bin/env fish

function hc
    herbstclient $argv
end

# Set up main workspace

# Right screen
hc focus_monitor right
hc use right_main
hc and , \
    rule once title="right_term" tag="right_main" , \
    spawn kitty --title right_term

# Left screen
hc focus_monitor left
hc use left_main
hc and , \
    rule once class="Signal" tag="left_main" index=1 , \
    spawn signal-desktop

# Main screen
hc focus_monitor main
hc use main_main
hc and , \
    rule once class="Vivaldi-stable" tag="main_main" index=0 , \
    rule once title="main_term" tag="main_main" index=1 , \
    spawn vivaldi , \
    spawn kitty --title="main_term" --hold --detach fastfetch

hc merge_tag default left_main

sleep 5
hc and , \
    focus_monitor main , \
    split explode 0.7

exit 0
