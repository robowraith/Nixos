{ config, pkgs, ... }:

{
  programs.herbstluftwm = {
    enable = true;
    # Use a custom config file
    configFile = "${config.xdg.configHome}/herbstluftwm/autostart";
  };

  # Write the autostart config to XDG config
  xdg.configFile."herbstluftwm/autostart".text = ''
    # Standard HerbstluftWM config
    hc() {
      herbstclient "$@"
    }
    
    # Split monitor into three side-by-side frames: 25%/50%/25%
    hc emit_hook reload
    hc chain ,
      add_tag main ,
      add_tag left ,
      add_tag right
    
    hc rename_monitor 0 main
    hc set_monitors 0x0 1920x1080
    hc chain ,
      split horizontal 0.25 ,
      split horizontal 0.5
    
    # Focus the middle frame
    hc focus_monitor 1
    
    # Set some basic keybindings
    hc keybind Mod4-Return spawn xterm
    hc keybind Mod4-q quit
    hc keybind Mod4-r reload
    hc keybind Mod4-h focus_monitor 0
    hc keybind Mod4-l focus_monitor 2
    hc keybind Mod4-m focus_monitor 1
    
    # Set default layout
    hc set_layout max
    
    # Set some colors
    hc attr theme.tiling.reset 1
    hc attr theme.floating.reset 1
    hc set frame_border_active_color '#5e81ac'
    hc set frame_border_normal_color '#4c566a'
    hc set window_border_active_color '#88c0d0'
    hc set window_border_normal_color '#3b4252'
  '';
}
