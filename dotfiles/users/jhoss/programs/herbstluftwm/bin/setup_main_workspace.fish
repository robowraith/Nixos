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
hc and , \
    rule once title="k9s_apps" tag="right_main" index=0 , \
    rule once title="k9s_dev" tag="right_main" index=1
alacritty --title k9s_apps --command k9s --context apps_cluster &
alacritty --title k9s_dev --command k9s --context dev_cluster &
wait_for_client k9s_apps
wait_for_client k9s_dev

# Left screen
hc focus_monitor left
hc use left_main
hc and , \
    rule once class="Slack" tag="left_main" index=0 , \
    rule once class="Signal" tag="left_main" index=1
slack &
signal-desktop &
wait_for_client Slack
wait_for_client Signal
hc split explode 0.7

# Main screen
hc focus_monitor main
hc use main_main
hc and , \
    rule once class="Vivaldi-stable" tag="main_main" index=0 , \
    rule once title="main_term" tag="main_main" index=1
vivaldi &
kitty --title="main_term" --working-directory ~/AI --hold --detach claude &
wait_for_client Vivaldi
wait_for_client main_term
hc split explode 0.715

disown

exit 0
