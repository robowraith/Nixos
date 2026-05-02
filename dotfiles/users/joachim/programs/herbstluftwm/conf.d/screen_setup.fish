#! /usr/bin/env fish

function hc
    herbstclient $argv
end

# Screen setup
autorandr --change
set -l current_profile (autorandr --detected | head -1)
switch $current_profile
    case "Work*"
        hc and , \
            set_monitors 1120x2160+0+0 1600x2160+1120+0 1120x2160+2720+0 , \
            rename_monitor 0 left , \
            rename_monitor 1 main , \
            rename_monitor 2 right
    case Gaming_4K
        hc and , \
            set_monitors 3840x2160+0+0 , \
            rename_monitor 0 main
    case Gaming_1080p
        hc and , \
            set_monitors 1920x1080+0+0 , \
            rename_monitor 0 main
end
