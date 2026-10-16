#! /usr/bin/env fish

# Toggle the sound card between Analog Stereo Duplex and HDMI output with
# analog input. The card is looked up by its profiles, so the same script
# works on every host regardless of the card's name.

set -l analog output:analog-stereo+input:analog-stereo
set -l hdmi output:hdmi-stereo+input:analog-stereo

# Prints "<card> <active profile>" for the first card offering the HDMI profile
set -l card (LC_ALL=C pactl list cards | awk -v hdmi=$hdmi '
    /^\tName: / { name = $2 }
    /^\tActive Profile: / { active[name] = $3 }
    /^\t\t[^\t]/ && $1 == hdmi ":" { has[name] = 1 }
    END { for (n in has) { print n, active[n]; exit } }
' | string split ' ')

if test (count $card) -ne 2
    dunstify -i audio-card "Audio profile" "No card with an HDMI + analog input profile"
    exit 1
end

if test $card[2] = $analog
    set -f target $hdmi
    set -f label "HDMI output + analog input"
else
    set -f target $analog
    set -f label "Analog stereo duplex"
end

if pactl set-card-profile $card[1] $target
    dunstify -i audio-card "Audio profile" $label
else
    dunstify -i dialog-error "Audio profile" "Could not switch to $label"
    exit 1
end
