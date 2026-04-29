#! /usr/bin/env fish

function hc
    herbstclient $argv
end

# Wait until herbstluftwm has registered a client whose title contains $argv[1]
function wait_for_client
    while true
        for winid in (hc list_clients 2>/dev/null)
            if string match -q "*$argv[1]*" -- (hc attr clients.$winid.title 2>/dev/null)
                return
            end
        end
        sleep 0.1
    end
end

# Set up main workspace

# Right screen
hc focus_monitor right
hc use right_main
hc rule once title="right_term" tag="right_main"
kitty --title right_term &
wait_for_client right_term

# Left screen
hc focus_monitor left
hc use left_main
hc rule once title="Signal" tag="left_main" index=1
signal-desktop &
wait_for_client Signal

# Main screen
hc focus_monitor main
hc use main_main
hc and , \
    rule once title="Vivaldi-stable" tag="main_main" index=0 , \
    rule once title="main_term" tag="main_main" index=1
vivaldi &
wait_for_client Vivaldi
kitty --title="main_term" --working-directory ~/AI --hold --detach claude &
wait_for_client main_term
hc split explode 0.715

disown

exit 0
