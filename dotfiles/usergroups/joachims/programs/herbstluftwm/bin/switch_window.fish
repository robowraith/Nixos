#! /usr/bin/env fish

# Script to switch windows

function hc
    herbstclient $argv
end

set sourcetagname (hc attr tags.focus.name)
set sourcewindowid (hc attr clients.focus.winid)
set direction $argv[1]
# set opposite_direction
switch $direction
    case left
        set opposite_direction right
    case right
        set opposite_direction left
    case up
        set opposite_direction down
    case down
        set opposite_direction up
end


hc and , \
    focus $direction , \
    move $sourcetagname , \
    bring $sourcewindowid , \
    focus $opposite_direction

exit 0
