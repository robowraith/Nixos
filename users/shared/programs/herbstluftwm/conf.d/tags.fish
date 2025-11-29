#! /usr/bin/env fish

# Script to set up tag layouts
hc set default_frame_layout vertical

# Set up Layout single use tag
hc and , \
    use private , \
    set_layout max
# Set up the "left" development tag
hc and , \
    use main , \
    set_layout max
exit 0
