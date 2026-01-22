#! /usr/bin/env fish

function hc
    herbstclient $argv
end

# Set up main workspace

# Layouts
# hc and , \
#     load left_main (split vertical:0.7:0 (clients vertical:0) (clients vertical:0)) , \
#     load main_main (split vertical:0.7:0 (clients vertical:0) (clients vertical:0)) , \
#     load right_main (clients vertical:0)

# Right screen
hc focus_monitor right
hc use right_main
hc and , \
    rule once title="k9s_apps" tag="right_main" index=0 , \
    rule once title="k9s_dev" tag="right_main" index=1 , \
    spawn alacritty --title k9s_apps --command k9s --context apps-cluster , \
    spawn alacritty --title k9s_dev --command k9s --context dev-cluster

# Left screen
hc focus_monitor left
hc use left_main
hc and , \
    rule once class="Slack" tag="left_main" index=0 , \
    rule once class="Signal" tag="left_main" index=1 , \
    spawn slack , \
    spawn signal-desktop
# sleep 3
# hc split explode 0.7

# Main screen
hc focus_monitor main
hc use main_main
hc and , \
    rule once class="Vivaldi-stable" tag="main_main" index=0 , \
    rule once title="main_term" tag="main_main" index=1 , \
    spawn vivaldi , \
    spawn kitty --title="main_term"
# sleep 3
# hc split explode 0.7

hc merge_tag default left_main

sleep 5
hc and , \
    focus_monitor left , \
    split explode 0.7

hc and , \
    focus_monitor main , \
    split explode 0.7

exit 0
