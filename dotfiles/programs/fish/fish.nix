{ config, pkgs, lib, ... }:

{
  programs.fish = {
    enable = true;
    
    # Configure Tide prompt on first run
    interactiveShellInit = ''
      # Configure Tide if not already configured
      if not set -q tide_prompt_configured
        tide configure --auto --style=Rainbow --prompt_colors='True color' --show_time='24-hour format' --rainbow_prompt_separators=Angled --powerline_prompt_heads=Sharp --powerline_prompt_tails=Flat --powerline_prompt_style='Two lines, character and frame' --prompt_connection=Disconnected --powerline_right_prompt_frame=Yes --prompt_connection_andor_frame_color=Lightest --prompt_spacing=Compact --icons='Many icons' --transient=Yes
        set -U tide_prompt_configured yes
      end
    '';
    
    plugins = with pkgs.fishPlugins; [
      { name = "tide"; src = tide.src; }
      { name = "fzf-fish"; src = fzf-fish.src; }
      { name = "bass"; src = bass.src; }
      { name = "plugin-git"; src = plugin-git.src; }
      { name = "autopair"; src = autopair.src; }
    ];
  };

  imports = [
    ./aliases.nix
    ./abbr.nix
    ./completions.nix
    ./functions.nix
    ./init.nix
  ];
}
