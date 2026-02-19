_: {
  # ============================================================================
  # Boot Configuration
  # ============================================================================

  boot = {
    # Kernel
    kernelParams = [
      # Enable Intel framebuffer compression for power saving
      "i915.enable_fbc=1"
      # Force DRM connector polling — helps re-detect HDMI after sleep/resume
      "drm_kms_helper.poll=1"
    ];
  };
}
