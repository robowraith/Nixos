#!/usr/bin/env fish

function hc
    herbstclient $argv
end

###############################
# Keybindings for HerbsluftWM #
###############################

# Set Mod to the super key
set Mod Mod4

#
# Mouse
#
hc mouseunbind --all
hc mousebind $Mod+Button1 move
hc mousebind $Mod+Button2 zoom
hc mousebind $Mod+Button3 resize

#
# Keyboard
#

# Genral Keybinds 
hc keyunbind --all
hc keybind $Mod+Ctrl+q quit
hc keybind $Mod+Ctrl+r reload
hc keybind $Mod+Shift+q close
hc keybind $Mod+Return spawn kitty

# basic movement
# Focus monitors
# hc keybind $Mod+r focus_monitor left
# hc keybind $Mod+i focus_monitor main
# hc keybind $Mod+e focus_monitor right
# hc keybind $Mod+o focus_monitor down

# Focus tags
hc keybind $Mod+1 spawn ~/.config/herbstluftwm/bin/switch_tag_or_cycle.fish left left_lower
# hc keybind $Mod+1 chain , \
#    focus_monitor 1 , \
#    use other1
hc keybind $Mod+2 spawn ~/.config/herbstluftwm/bin/switch_tag_or_cycle.fish main main_lower
# hc keybind $Mod+2 chain , \
#    focus_monitor 2 , \
#    use editor
hc keybind $Mod+3 spawn ~/.config/herbstluftwm/bin/switch_tag_or_cycle.fish right right_lower
# hc keybind $Mod+3 chain , \
#    focus_monitor 3 , \
#    use other2
hc keybind $Mod+4 spawn ~/.config/herbstluftwm/bin/switch_tag_or_cycle.fish left left_main
# hc keybind $Mod+4 chain , \
#    focus_monitor 1 , \
#    use terminal
hc keybind $Mod+5 spawn ~/.config/herbstluftwm/bin/switch_tag_or_cycle.fish main main_main
#hc keybind $Mod+5 chain , \
#    focus_monitor 2 , \
#    use web
hc keybind $Mod+6 spawn ~/.config/herbstluftwm/bin/switch_tag_or_cycle.fish right right_main
# hc keybind $Mod+6 chain , \
#    focus_monitor 3 , \
#    use chat
hc keybind $Mod+7 spawn ~/.config/herbstluftwm/bin/switch_tag_or_cycle.fish left left_upper
# hc keybind $Mod+7 chain , \
#    focus_monitor 1 , \
#    use left
hc keybind $Mod+8 spawn ~/.config/herbstluftwm/bin/switch_tag_or_cycle.fish main main_upper
# hc keybind $Mod+8 chain , \
#    focus_monitor 2 , \
#    use main
hc keybind $Mod+9 spawn ~/.config/herbstluftwm/bin/switch_tag_or_cycle.fish right right_upper
# hc keybind $Mod+9 chain , \
#    focus_monitor 3 , \
#    use right
hc keybind $Mod+0 spawn ~/.config/herbstluftwm/bin/switch_tag_or_cycle.fish down down
# hc keybind $Mod+0 chain , \
# focus_monitor 0 , \
# use private
# hc keybind $Mod+0 spawn ~/.config/herbstluftwm/bin/switch_tag_0.fish

# hc keybind $Mod+Ctrl+u use_previous

# focusing clients
hc keybind $Mod+Left focus left
hc keybind $Mod+Down focus down
hc keybind $Mod+Up focus up
hc keybind $Mod+Right focus right

# Fullscreen
hc keybind $Mod+Shift+f fullscreen
hc keybind $Mod+Ctrl+f spawn ~/.config/herbstluftwm/bin/fullscreen_window.fish
# hc keybind $Mod+Shift+f fullscreen toggle

# moving clients
hc keybind $Mod+Shift+Left shift left
hc keybind $Mod+Shift+Down shift down
hc keybind $Mod+Shift+Up shift up
hc keybind $Mod+Shift+Right shift right

# Move client to tag
hc keybind $Mod+Shift+1 move left_lower
hc keybind $Mod+Shift+2 move main_lower
hc keybind $Mod+Shift+3 move right_lower
hc keybind $Mod+Shift+4 move left_main
hc keybind $Mod+Shift+5 move main_main
hc keybind $Mod+Shift+6 move right_main
hc keybind $Mod+Shift+7 move left_upper
hc keybind $Mod+Shift+8 move main_upper
hc keybind $Mod+Shift+9 move right_upper
hc keybind $Mod+Shift+0 move down

# Bring tag to monitor
hc keybind $Mod+Ctrl+1 use left_lower
hc keybind $Mod+Ctrl+2 use main_lower
hc keybind $Mod+Ctrl+3 use right_lower
hc keybind $Mod+Ctrl+4 use left_main
hc keybind $Mod+Ctrl+5 use main_main
hc keybind $Mod+Ctrl+6 use right_main
hc keybind $Mod+Ctrl+7 use left_upper
hc keybind $Mod+Ctrl+8 use main_upper
hc keybind $Mod+Ctrl+9 use right_upper
hc keybind $Mod+Ctrl+0 use down

# Switching adjacent windows
# hc keybind $Mod+Ctrl+Left spawn ~/.config/herbstluftwm/bin/switch_window.fish left
# hc keybind $Mod+Ctrl+Down spawn ~/.config/herbstluftwm/bin/switch_window.fish down
# hc keybind $Mod+Ctrl+Up spawn ~/.config/herbstluftwm/bin/switch_window.fish up
# hc keybind $Mod+Ctrl+Right spawn ~/.config/herbstluftwm/bin/switch_window.fish right

# splitting frames
# create an empty frame at the specified direction
hc keybind $Mod+Ctrl+Shift+Left split left 0.5
hc keybind $Mod+Ctrl+Shift+Down split bottom 0.5
hc keybind $Mod+Ctrl+Shift+Up split up 0.5
hc keybind $Mod+Ctrl+Shift+Right split right 0.5
hc keybind $Mod+Ctrl+e split explode
hc keybind $Mod+Ctrl+a split auto
hc keybind $Mod+r remove

# Switching Modes
hc keybind $Mod+f floating toggle
hc keybind $Mod+p pseudotile toggle

# .Rofi
hc keybind $Mod+space spawn rofi -combi-modi drun,run -show combi -config ~/.config/rofi/jolauncher.rasi
hc keybind $Mod+w spawn rofi -modi window -show window -config ~/.config/rofi/jowindow.rasi
# hc keybind $Mod+Shift+w spawn ~/.config/herbstluftwm/bin/workspaces.sh
hc keybind $Mod+s spawn rofi -modi ssh -show ssh -config ~/.config/rofi/jossh.rasi
hc keybind $Mod+Shift+s spawn ~/.config/rofi/sshtunnel
hc keybind $Mod+Shift+p spawn rofi -show p -modi p:rofi-power-menu -config ~/.config/rofi/jolauncher.rasi

# resizing frames
set resizestep 0.05
hc keybind $Mod+Control+Left resize left +$resizestep
hc keybind $Mod+Control+Down resize down +$resizestep
hc keybind $Mod+Control+Up resize up +$resizestep
hc keybind $Mod+Control+Right resize right +$resizestep

# # layouting
# hc keybind $Mod+r remove
# hc keybind $Mod+s floating toggle
# hc keybind $Mod+f fullscreen toggle
# hc keybind $Mod+p pseudotile toggle
# # The following cycles through the available layouts within a frame, but skips
# # layouts, if the layout change wouldn't affect the actual window positions.
# # I.e. if there are two windows within a frame, the grid layout is skipped.
hc keybind $Mod+Ctrl+space \
    or , and . compare tags.focus.curframe_wcount = 2 \
    . cycle_layout +1 vertical horizontal max grid \
    , cycle_layout +1

# # focus
# hc keybind $Mod+BackSpace cycle_monitor
# hc keybind $Mod+Tab cycle_all +1
# hc keybind $Mod+Shift+Tab cycle_all -1
hc keybind $Mod+Tab cycle
# hc keybind $Mod+c cycle
# hc keybind $Mod+Shift+x jumpto urgent

###################
# Multimedia Keys #
###################

# Use pactl to adjust volume in PulseAudio.
hc keybind XF86AudioRaiseVolume spawn pactl set-sink-volume @DEFAULT_SINK@ +10%
hc keybind XF86AudioLowerVolume spawn pactl set-sink-volume @DEFAULT_SINK@ -10%
hc keybind XF86AudioMute spawn pactl set-sink-mute @DEFAULT_SINK@ toggle
hc keybind XF86AudioMicMute spawn pactl set-source-mute @DEFAULT_SOURCE@ toggle

# Media player controls
hc keybind XF86AudioPlay spawn playerctl play-pause
hc keybind XF86AudioPause spawn playerctl play-pause
hc keybind XF86AudioNext spawn playerctl next
hc keybind XF86AudioPrev spawn playerctl previous

# Switch camera light
hc keybind $Mod+Shift+l spawn litra on
hc keybind $Mod+Ctrl+l spawn litra off

#######################
# Application Hotkeys #
#######################

hc keybind Control+space spawn copyq show
hc keybind Print spawn flameshot gui
hc keybind $Mod+Ctrl+d spawn dunstctl close
hc keybind $Mod+Shift+Ctrl+d spawn dunstctl close-all
