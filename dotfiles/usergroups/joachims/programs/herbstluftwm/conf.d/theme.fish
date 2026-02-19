#! /usr/bin/env fish

function hc
    herbstclient $argv
end

# Themeing for HerbstluftWM

# Colors
set -l red '#FF0000'
set -l yellow '#FFFF00'
set -l gray '#808080'
set -l white '#FFFFFF'
set -l black '#000000'

# Themeing the frames
hc and , \
    set frame_gap 0 , \
    set frame_border_width 0 , \
    set frame_normal_opacity 0 , \
    set frame_active_opacity 0 , \
    set frame_bg_transparent 1

# Themeing the windows
hc and , \
    attr theme.reset all , \
    set window_gap 5 , \
    attr theme.outer_width 5 , \
    attr theme.border_width 5 , \
    attr theme.outer_color $gray , \
    attr theme.normal.color $gray , \
    attr theme.normal.tab_color $black , \
    attr theme.normal.outer_color $gray , \
    attr theme.active.color $yellow , \
    attr theme.active.tab_color $gray , \
    attr theme.active.outer_color $yellow , \
    attr theme.urgent.color $red , \
    attr theme.urgent.outer_color $red , \
    attr theme.urgent.tab_color $gray , \
    attr theme.title_when multiple_tabs , \
    attr theme.title_height 30 , \
    attr theme.title_depth 10 , \
    attr theme.title_align center , \
    attr theme.normal.title_color $white
