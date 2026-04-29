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

set workingdirectory ~/code/ansible

# Right screen
hc focus_monitor right
hc use right_upper
hc and , \
    rule once title="ansible_git" tag="right_upper" index=0 , \
    rule once title="ansible_term" tag="right_upper" index=1
kitty --title ansible_git --working-directory $workingdirectory --detach lazygit &
wait_for_client ansible_git
kitty --title ansible_term --working-directory $workingdirectory &
wait_for_client ansible_term
hc split explode 0.7

# Left screen
hc focus_monitor left
hc use left_upper
hc and , \
    rule once title="ansible_dev" tag="left_upper" index=0 , \
    rule once title="ansible_vargrant" tag="left_upper" index=1
kitty --title ansible_dev --working-directory $workingdirectory &
wait_for_client ansible_dev
kitty --title ansible_vargrant --working-directory $workingdirectory/vagrant &
wait_for_client ansible_vargrant
hc split explode 0.7

# Main screen
hc focus_monitor main
hc use main_upper
hc and , \
    rule once title="ansible - Visual Studio Code" tag="main_upper" index=0 , \
    rule once title="ansible_gemini" tag="main_upper" index=1
code $workingdirectory &
wait_for_client "Visual Studio Code"
kitty --title ansible_gemini --working-directory $workingdirectory --detach claude &
wait_for_client ansible_gemini
hc split explode 0.715

hc focus_monitor main
exit 0
