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

set workingdirectory ~/nixos

# Left screen
hc focus_monitor left
hc use left_lower
hc rule once title="nixos_term" tag="left_lower"
kitty --title nixos_term --working-directory $workingdirectory &
wait_for_client nixos_term

# Right screen
hc focus_monitor right
hc use right_lower
hc rule once title="nixos_git" tag="right_lower"
kitty --title nixos_git --working-directory $workingdirectory --detach lazygit &
wait_for_client nixos_git

# Main screen
hc focus_monitor main
hc use main_lower
hc and , \
    rule once title="nixos - Visual Studio Code" tag="main_lower" index=0 , \
    rule once title="nixos_gemini" tag="main_lower" index=1
code $workingdirectory &
wait_for_client "Visual Studio Code"
kitty --title nixos_gemini --working-directory $workingdirectory --detach claude &
wait_for_client nixos_gemini
hc merge_tag default left_main
hc split explode 0.715

exit 0
