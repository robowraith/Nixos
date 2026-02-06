#!/usr/bin/env fish

# Error msg
function msg
    rofi -theme "$HOME/.config/rofi/jomenu.rasi.rasi" -e "$argv"
end

function hc
    herbstclient $argv
end

# Links
set ansible_vscode Ansible_VSCode
set ansible_helix Ansible_Helix
set nixos_vscode Nixos_VSCode
set nixos_helix Nixos_Helix

# Variable passed to rofi
set options "$ansible_vscode\n$ansible_helix\n$nixos_vscode\n$nixos_helix"

set chosen (echo -e "$options" | rofi -theme ~/.config/rofi/joworkspace.rasi -p "Set up which Workspace?" -dmenu -selected-row 0)
switch $chosen
    case "$ansible_vscode"
        cd /home/jhoss/code/ansible
        hc spawn /home/jhoss/.config/herbstluftwm/bin/setup_ansible_workspace_with_vscode.fish

    case "$ansible_helix"
        cd /home/jhoss/code/ansible
        hc spawn /home/jhoss/.config/herbstluftwm/bin/setup_ansible_workspace_with_helix.fish

    case "$nixos_vscode"
        cd /home/jhoss/nixos
        hc spawn /home/jhoss/.config/herbstluftwm/bin/setup_nixos_workspace_with_vscode.fish

    case "$nixos_helix"
        cd /home/jhoss/nixos
        hc spawn /home/jhoss/.config/herbstluftwm/bin/setup_nixos_workspace_with_helix.fish
end
