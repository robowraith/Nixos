_: {
  # ============================================================================
  # X Server Configuration
  # ============================================================================

  # Disable DPMS (Display Power Management Signaling) to prevent the X server
  # from sending power-save signals to external monitors. The Samsung Odyssey Ark
  # does not reliably re-establish the HDMI link after DPMS standby/suspend,
  # causing both video and audio (HDMI sink) to become unavailable on wake.
  # System suspend still works — this only disables X-level screen blanking.
  services.xserver.serverFlagsSection = ''
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
  '';
}
