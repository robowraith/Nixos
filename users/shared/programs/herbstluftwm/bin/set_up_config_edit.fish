#! /usr/bin/env fish

set configdir ~/.config

# rules
hc rule title="nvim_config" tag="editor"

# Start applications
hc spawn /usr/bin/kitty \
    --title nvim_config \
    --working-directory $configdir \
    --detach /usr/bin/nvim
