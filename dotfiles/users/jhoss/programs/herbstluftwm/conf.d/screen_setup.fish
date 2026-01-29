#! /usr/bin/env fish

function hc
    herbstclient $argv
end

# Screen setup
switch $AUTORANDR_CURRENT_PROFILE
    case "Work*"
        hc and , \
            set_monitors 1120x2160+0+0 1600x2160+1120+0 1120x2160+2720+0 , \
            rename_monitor 0 left , \
            rename_monitor 1 main , \
            rename_monitor 2 right

    case Gaming_1080p
        hc and , \
            set_monitors 1920x1080+0+0 , \
            rename_monitor 0 main

    case Gaming_4K
        hc and , \
            set_monitors 3840x2160+0+0 , \
            rename_monitor 0 main

    case Notebook_1200
        hc and , \
            set_monitors 1920x1200+0+0 , \
            rename_monitor 0 main

    case Notebook_USBC
        hc and , \
            set_monitors 1920x1200+0+0 1920x1200+1920+0 , \
            rename_monitor 0 main , \
            rename_monitor 1 up
end
