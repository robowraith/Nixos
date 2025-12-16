#! /usr/bin/env fish

# Screen setup
switch $AUTORANDR_CURRENT_PROFILE
    case Office_4K
        hc and , \
            set_monitors 1600x560+1120+1600 1120x2160+0+0 1600x1600+1120+0 1120x2160+2780+0 , \
            rename_monitor 0 down , \
            rename_monitor 1 left , \
            rename_monitor 2 main , \
            rename_monitor 3 right
end

# Wallpaper
/usr/bin/feh --no-fehbg --bg-fill ~/wallpaper/BladeRunnerWP.jpg
