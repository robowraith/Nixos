#!/usr/bin/env bash

rofi_command="rofi -theme ~/.config/rofi/joworkspace.rasi"

# Error msg
msg() {
	rofi -theme "$HOME/.config/rofi/jomenu.rasi.rasi" -e "$1"
}

# Links
ansiblework="Ansible (work)"
puppet="Puppet"
ansiblehome="Ansible (home)"
configeditor="Config editor"
# Variable passed to rofi
options="$ansiblework\n$ansiblehome\n$puppet\n$configeditor"

chosen="$(echo -e "$options" | $rofi_command -p "Set up which Workspace?" -dmenu -selected-row 0)"
case $chosen in
"$ansiblework")
	'cd /home/joachim/code/ansible/ || return'
	/home/joachim/.config/herbstluftwm/bin/set_up_ansible_ws_work.fish &
	;;
"$puppet")
	'cd /home/joachim/Privat/code/puppet_files/ || return'
	/home/joachim/.config/herbstluftwm/bin/set_up_puppet_ws.fish &
	;;
"$ansiblehome")
	'cd /home/joachim/Privat/code/ansible/ || return'
	/home/joachim/.config/herbstluftwm/bin/set_up_ansible_ws_home.fish &
	;;
"$configeditor")
	'cd /home/joachim/.config/ || return'
	/home/joachim/.config/herbstluftwm/bin/set_up_config_edit.fish &
	;;

esac
