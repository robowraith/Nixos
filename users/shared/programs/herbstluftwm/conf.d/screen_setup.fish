#! /usr/bin/env fish

function hc
    herbstclient $argv
end

# Screen setup
if test (xrandr --listmonitors | grep 'DP2')
    if test (xrandr --listmonitors | grep '.DP2 3840')
        set screen1 DP2
        set screen2 DP1
    else
        set screen1 DP1
        set screen2 DP2
    end

    xrandr \
        --output eDP1 \
        --mode 1680x1050 \
        --pos 1080x1800 \
        --output $screen1 \
        --primary \
        --mode 3840x1600 \
        --pos 0x200 \
        --rate 75 \
        --rotate normal \
        --output $screen2 \
        --mode 2560x1440 \
        --pos 3840x0 \
        --rate 60 \
        --rotate left

    # Add monitors
    hc and , \
        set_monitors 1680x1050+1080+1800 3840x1600+0+200 1440x2560+3840+0 , \
        rename_monitor 1 main , \
        rename_monitor 2 left , \
        rename_monitor 0 down

    # Add padding for panel
    hc pad 1 "" 35 "" ""

else if test (xrandr --listmonitors | grep 'HDMI-0')

    xrandr \
        --output HDMI-0 \
        --mode 3840x2160 \
        --rate 60 \
        --pos 0x0 \
        --rotate normal

    # Add monitors
    hc and , \
        set_monitors 1600x960+1120+1200 1120x2160+0+0 1600x1200+1120+0 1120x2160+2720+0 , \
        rename_monitor 1 left , \
        rename_monitor 2 main , \
        rename_monitor 3 right , \
        rename_monitor 0 down

    # Add padding for panel
    hc pad 3 "" 35 "" ""

else if test (xrandr --listmonitors | grep ' DP1')

    xrandr \
        --output eDP1 \
        --mode 1680x1050 \
        --rate 90 \
        --pos 0x1600 \
        --output DP1 \
        --mode 3840x1600 \
        --rate 30 \
        --pos 1600x0 \
        --rotate normal

    # Add monitors
    hc and , \
        set_monitors 1680x1050+0+1600 1120x1600+1600+0 1600x1600+2720+0 1120x1600+4320+0 , \
        rename_monitor 1 left , \
        rename_monitor 2 main , \
        rename_monitor 3 right , \
        rename_monitor 0 down

    # Add padding for panel
    hc pad 3 "" 35 "" ""

else
    xrandr \
        --output eDP1 \
        --primary \
        --mode 1680x1050 \
        --rate 90

    # Add monitors
    hc and , \
        set_monitors 1680x1050+0+0 , \
        rename_monitor 0 main

    # Add padding for panel
    hc pad 0 "" 35 "" ""

end

# Wallpaper
# feh --no-fehbg --bg-fill ~/wallpaper/Pillars1.jpg
~/.fehbg
