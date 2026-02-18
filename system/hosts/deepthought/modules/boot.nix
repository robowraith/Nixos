_: {
  # ============================================================================
  # Boot Configuration
  # ============================================================================

  boot = {
    # Kernel
    kernelParams = [
      # Enable Intel framebuffer compression for power saving
      "i915.enable_fbc=1"
    ];
  };
}
