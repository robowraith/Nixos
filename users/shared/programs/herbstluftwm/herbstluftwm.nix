{ config, pkgs, ... }:

{
  # HerbstluftWM is enabled system-wide via services.xserver.windowManager.herbstluftwm
  # No need to install it here or configure xsession - that's handled by NixOS
  # We only need to configure the autostart script

  # Write the autostart config to XDG config
  xdg.configFile."herbstluftwm/autostart" = {
    text = ''
      #!/usr/bin/env bash
      
      # Standard HerbstluftWM config
      hc() {
        herbstclient "$@"
      }
      
      # Remove all existing frames
      hc emit_hook reload
      
      # Create tags
      hc add_tag main
      
      # Split monitor into three side-by-side frames: 25%/50%/25%
      # First split: 25% left, 75% right
      hc split left 0.25
      # Focus right frame and split: 66.67% (which is 50% of total), 33.33% (which is 25% of total)
      hc focus right
      hc split right 0.3333
      
      # Focus the middle frame
      hc focus left
      
      # Set some basic keybindings
      hc keybind Mod4-Return spawn kitty
      hc keybind Mod4-Shift-q quit
      hc keybind Mod4-Shift-r reload
      hc keybind Mod4-h focus left
      hc keybind Mod4-l focus right
      hc keybind Mod4-j focus down
      hc keybind Mod4-k focus up
      hc keybind Mod4-c close
      
      # Set frame layout
      hc set_layout max
      hc set frame_gap 5
      hc set window_gap 5
      hc set frame_padding 0
      hc set smart_window_surroundings off
      hc set smart_frame_surroundings on
      hc set mouse_recenter_gap 0
      
      # Set some colors
      hc attr theme.tiling.reset 1
      hc attr theme.floating.reset 1
      hc set frame_border_active_color '#5e81ac'
      hc set frame_border_normal_color '#4c566a'
      hc set window_border_active_color '#88c0d0'
      hc set window_border_normal_color '#3b4252'
      hc set frame_bg_transparent on
      hc set frame_transparent_width 0
      hc set frame_border_width 2
      
      # Unlock and layout
      hc unlock
    '';
    executable = true;
  };
}
