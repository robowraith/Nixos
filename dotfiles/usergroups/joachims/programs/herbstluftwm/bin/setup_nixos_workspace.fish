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

set workingdirectory ~/nixos

# Right screen
hc focus_monitor right
hc use right_lower
hc and , \
    rule once title="nixos_git" tag="right_lower" , \
    spawn kitty --title nixos_git --working-directory $workingdirectory --detach lazygit

# Left screen
hc focus_monitor left
hc use left_lower
hc and , \
    rule once class="nixos_term" tag="left_lower" , \
    spawn kitty --title nixos_term --working-directory $workingdirectory

# Main screen
hc focus_monitor main
hc use main_lower
hc and , \
    rule once class="nixos_main" tag="main_lower" index=0 , \
    rule once title="nixos_gemini" tag="main_lower" index=1 , \
    spawn kitty --title nixos_main --working-directory $workingdirectory --detach lf , \
    spawn kitty --title nixos_gemini --working-directory $workingdirectory --detach gemini ,
hc merge_tag default left_main

# sleep 5
hc and , \
    focus_monitor main , \
    split explode 0.7

exit 0
