#! /usr/bin/env fish

# Script to switch to tag 0 if not on tag 0 and to cycle clients if already on tag 0

if test (hc attr tags.focus.name) = private
    hc cycle +1
else
    hc chain , \
        focus_monitor 0 , \
        use private
end

exit 0
