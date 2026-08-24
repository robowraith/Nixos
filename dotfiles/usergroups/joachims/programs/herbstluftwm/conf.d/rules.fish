#! /usr/bin/env fish

function hc
    herbstclient $argv
end

hc set swap_monitors_to_get_tag 1
hc set focus_stealing_prevention off

# Permanent rules for HerbstluftWM
hc unrule --all
hc rule focus=on
# Apps that remember their own window size (kitty, Electron) request whatever
# geometry they last had - possibly from the 3840x2160 fullscreen monitor. That
# becomes the client's floating_geometry, so at least center it on whichever
# monitor it lands on instead of letting it start off-screen.
hc rule floatplacement=center
hc rule windowtype~'_NET_WM_WINDOW_TYPE_(DIALOG|UTILITY|SPLASH)' pseudotile=on
hc rule windowtype='_NET_WM_WINDOW_TYPE_DIALOG' focus=on
hc rule windowtype~'_NET_WM_WINDOW_TYPE_(NOTIFICATION|DOCK|DESKTOP)' manage=off
hc rule class='copyq' floating=on floatplacement=center
hc rule class='vicinae' floating=on floatplacement=center
