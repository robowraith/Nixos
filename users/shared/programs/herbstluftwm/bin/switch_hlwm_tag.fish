#! /usr/bin/env fish
set -l target_monitor $argv[1]
set -l focused_monitor (hc attr monitors.focus.index)

if test $target_monitor -ne $focused_monitor
    hc focus_monitor $target_monitor
    exit 0
else
    set -l focused_tag (hc attr tags.focus.name)
    set -l tag_number (string split -m 1 -f 2 --right _ $focused_tag)
    set -l target_number
    if test $tag_number -eq 2
        set target_number 0
    else
        set target_number (math $tag_number + 1)
    end
    hc use "$focused_monitor"_"$target_number"
    exit 0
end

exit 1
