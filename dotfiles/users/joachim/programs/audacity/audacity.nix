{pkgs, ...}: {
  # Multitrack recorder/editor, used here to digitise tapes from the USB
  # cassette converter (capture-only USB audio class device, s16le 2ch 48 kHz).
  # PipeWire's ALSA layer already exposes it, so no extra audio config is needed;
  # pick "USB PnP Audio Device" as the recording device inside Audacity.
  home.packages = with pkgs; [
    audacity
  ];
}
