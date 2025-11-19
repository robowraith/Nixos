{ config, pkgs, lib, ... }:

{
  programs.fish = {
    enable = true;
    plugins = with pkgs.fishPlugins; [
      { name = "tide"; src = tide.src; }
      { name = "fzf-fish"; src = fzf-fish.src; }
      { name = "bass"; src = bass.src; }
      { name = "plugin-git"; src = plugin-git.src; }
      { name = "autopair"; src = autopair.src; }
      # {
      #   name = "fish-abbreviation-tips";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "gazorby";
      #     repo = "fish-abbreviation-tips";
      #     rev = "v0.7.0";
      #     sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Placeholder, replace with actual hash
      #   };
      # }
      # {
      #   name = "replay.fish";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "jorgebucaran";
      #     repo = "replay.fish";
      #     rev = "main"; # Or a specific tag/commit
      #     sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Placeholder, replace with actual hash
      #   };
      # }
    ];
  };

  # Configure Tide-Plugin
  home.activation.configure-tide = lib.hm.dag.entryAfter ["linkGeneration"] ''
    ${pkgs.fish}/bin/fish -c "tide configure --auto --style=Rainbow --prompt_colors='True color' --show_time='24-hour format' --rainbow_prompt_separators=Angled --powerline_prompt_heads=Sharp --powerline_prompt_tails=Flat --powerline_prompt_style='Two lines, character and frame' --prompt_connection=Disconnected --powerline_right_prompt_frame=Yes --prompt_connection_andor_frame_color=Lightest --prompt_spacing=Compact --icons='Many icons' --transient=Yes"
  '';

  imports = [
    ./aliases.nix
    ./abbr.nix
    ./completions.nix
    ./functions.nix
    ./init.nix
  ];
}
