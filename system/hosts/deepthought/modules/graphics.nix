{pkgs, ...}: {
  # ============================================================================
  # Hardware Configuration - Intel Iris Xe Graphics
  # Tuxedo InfinityBook 14 Gen 6
  # ============================================================================

  # Enable hardware-accelerated graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD (recommended for Iris Xe)
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (fallback)
      vpl-gpu-rt # Intel Quick Sync Video
    ];
  };

  # Uses the modesetting DDX driver (NixOS default, recommended over deprecated intel DDX).
  # Note: The modesetting driver cannot set non-native resolutions on the eDP panel
  # via xrandr --mode. Use xrandr --scale instead for lower effective resolutions, e.g.:
  #   xrandr --output eDP-1 --scale 0.667x0.667  (for effective 1920x1200)

  # Prefer the iHD VA-API driver for Iris Xe
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
