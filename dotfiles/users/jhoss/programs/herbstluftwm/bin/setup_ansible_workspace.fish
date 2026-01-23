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

set workingdirectory ~/code/ansible

# Right screen
hc focus_monitor right
hc use right_upper
hc and , \
    rule once title="ansible_git" tag="right_upper" index=0 , \
    rule once title="ansible_term" tag="right_upper" index=1 , \
    spawn kitty --title ansible_git --working-directory $workingdirectory --detach lazygit , \
    spawn kitty --title ansible_term --working-directory $workingdirectory

# Left screen
hc focus_monitor left
hc use left_upper
hc and , \
    rule once class="ansible_dev" tag="left_upper" index=0 , \
    rule once class="ansible_vargrant" tag="left_upper" index=1 , \
    spawn kitty --title ansible_dev --working-directory $workingdirectory , \
    spawn kitty --title ansible_term --working-directory $workingdirectory/vagrant

# Main screen
hc focus_monitor main
hc use main_upper
hc and , \
    rule once class="ansible_main" tag="main_upper" index=0 , \
    rule once title="ansible_gemini" tag="main_upper" index=1 , \
    spawn kitty --title ansible_main --working-directory $workingdirectory --detach lf , \
    spawn kitty --title ansible_gemini --working-directory $workingdirectory --detach gemini ,
hc merge_tag default left_main

# sleep 5
hc and , \
    focus_monitor right , \
    split explode 0.7

hc and , \
    focus_monitor left , \
    split explode 0.7

hc and , \
    focus_monitor main , \
    split explode 0.7

exit 0
