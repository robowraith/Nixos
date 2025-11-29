#! /usr/bin/env fish

set puppetdir ~/code/puppet_files/environments/production

# rules
hc rule title="nvim_puppet" tag="main"
hc rule title="db2_puppet" tag="right"
hc rule title="ssh_puppet" tag="right"

# Start applications
hc spawn /usr/bin/alacritty \
    --title db2_puppet \
    --working-directory $puppetdir \
    --command /usr/bin/ssh db2

hc spawn /usr/bin/alacritty \
    --title ssh_puppet \
    --working-directory $puppetdir

hc spawn /usr/bin/kitty \
    --title nvim_puppet \
    --working-directory $puppetdir \
    --detach /usr/bin/nvim
