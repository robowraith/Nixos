{pkgs, lib, ...}: {
  systemd.user.services.fix-monitor-on-resume = {
    Unit = {
      Description = lib.mkForce "Fix Samsung Odyssey Ark HDMI/audio on resume from sleep";
      After = ["suspend.target" "hibernate.target" "hybrid-sleep.target"];
    };

    Service = {
      Type = "oneshot";
      ExecStart = lib.mkForce "${pkgs.writeShellScript "fix-monitor-on-resume" ''
        #!/bin/sh
        export DISPLAY=:0
        export XAUTHORITY=/home/jhoss/.Xauthority

        # Wait for the system to fully resume and the i915 driver to settle
        sleep 5

        # Re-trigger HDMI hotplug detection by cycling the output
        ${pkgs.xrandr}/bin/xrandr --output HDMI-1 --off
        sleep 2

        # Re-enable HDMI and let autorandr pick the right profile
        ${pkgs.xrandr}/bin/xrandr --output HDMI-1 --auto
        sleep 1
        ${pkgs.autorandr}/bin/autorandr --change

        # Restart PipeWire to re-detect HDMI audio sinks
        ${pkgs.systemd}/bin/systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service
        sleep 2

        # Re-apply autorandr in case PipeWire restart affected anything
        ${pkgs.autorandr}/bin/autorandr --change
      ''}";
    };

    Install.WantedBy = ["suspend.target" "hibernate.target" "hybrid-sleep.target"];
  };
}
