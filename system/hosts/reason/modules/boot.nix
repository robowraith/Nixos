{...}: {
  # ============================================================================
  # Boot Configuration
  # ============================================================================

  boot = {
    # Kernel
    kernelParams = [
      "nvidia-drm.modeset=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
  };
}
