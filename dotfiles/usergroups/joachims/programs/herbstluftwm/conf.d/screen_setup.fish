#! /usr/bin/env fish

function hc
    herbstclient $argv
end

# Screen setup
switch $AUTORANDR_CURRENT_PROFILE
    case Office_4K
        hc and , \
            set_monitors 1120x2160+0+0 1600x2160+1120+0 1120x2160+2720+0 , \
            rename_monitor 0 left , \
            rename_monitor 1 main , \
            rename_monitor 2 right
end

# Wallpaper
feh --no-fehbg --bg-fill ~/Bilder/Wallpaper/Rechner/BladeRunnerWP.jpg
