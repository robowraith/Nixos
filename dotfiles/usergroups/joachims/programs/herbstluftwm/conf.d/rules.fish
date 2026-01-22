#! /usr/bin/env fish

function hc
    herbstclient $argv
end

hc set swap_monitors_to_get_tag 1
hc set focus_stealing_prevention off

# Permanent rules for HerbstluftWM
hc unrule --all
hc rule focus=on
hc rule windowtype~'_NET_WM_WINDOW_TYPE_(DIALOG|UTILITY|SPLASH)' pseudotile=on
hc rule windowtype='_NET_WM_WINDOW_TYPE_DIALOG' focus=on
hc rule windowtype~'_NET_WM_WINDOW_TYPE_(NOTIFICATION|DOCK|DESKTOP)' manage=off
hc rule class='copyq' floating=on floatplacement=center
