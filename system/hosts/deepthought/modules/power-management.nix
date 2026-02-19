{
  pkgs,
  lib,
  ...
}: {
  # ============================================================================
  # Power Management - Tuxedo InfinityBook 14 Gen 6
  # Intel Core i7-11370H (4 cores / 8 threads)
  #
  # Replaces Tuxedo Control Center functionality:
  # - auto-cpufreq: Automatic CPU governor & turbo switching (AC vs battery)
  # - thermald: Intel thermal management
  # - tuxedo-drivers: Fan control & keyboard backlight
  # - Custom udev/systemd: Core toggling on power source change
  # ============================================================================

  # ---------------------------------------------------------------------------
  # Tuxedo Hardware Support
  # ---------------------------------------------------------------------------
  hardware.tuxedo-drivers.enable = true;

  # ---------------------------------------------------------------------------
  # Intel Thermal Daemon
  # ---------------------------------------------------------------------------
  services.thermald.enable = true;

  # ---------------------------------------------------------------------------
  # auto-cpufreq - Automatic CPU Frequency Scaling
  # ---------------------------------------------------------------------------
  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        # On AC power: maximize performance
        governor = "performance";
        turbo = "auto";
        # Allow full frequency range
        scaling_min_freq = 400000; # 400 MHz
        scaling_max_freq = 4800000; # 4.8 GHz (max turbo)
        energy_performance_preference = "performance";
      };
      battery = {
        # On battery: conserve power
        governor = "powersave";
        turbo = "never";
        # Limit max frequency to save battery
        scaling_min_freq = 400000; # 400 MHz
        scaling_max_freq = 2200000; # 2.2 GHz (well below turbo)
        energy_performance_preference = "power";
      };
    };
  };

  # ---------------------------------------------------------------------------
  # CPU Core Toggling on Power Source Change
  #
  # On AC:      All 8 logical CPUs active (cpu0-cpu7)
  # On Battery: Only 4 logical CPUs active (cpu0-cpu3), cpu4-cpu7 disabled
  #
  # cpu0 cannot be offlined on Linux, so it is always skipped.
  # ---------------------------------------------------------------------------
  environment.systemPackages = [pkgs.power-profiles-daemon]; # for powerprofilesctl (optional monitoring)

  # Script that toggles CPU cores based on power source
  environment.etc."power-management/toggle-cores.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      # Toggle CPU cores based on AC/battery status
      # AC0/online: 1 = on AC, 0 = on battery

      AC_STATUS=$(cat /sys/class/power_supply/AC0/online 2>/dev/null || echo "1")

      if [ "$AC_STATUS" = "1" ]; then
        echo "AC power detected — enabling all CPU cores"
        # Enable cpu4-cpu7 (cpu0-cpu3 stay on, cpu0 can't be offlined)
        for cpu in 4 5 6 7; do
          echo 1 > /sys/devices/system/cpu/cpu''${cpu}/online 2>/dev/null || true
        done
      else
        echo "Battery power detected — disabling half the CPU cores"
        # Disable cpu4-cpu7 to save power
        for cpu in 4 5 6 7; do
          echo 0 > /sys/devices/system/cpu/cpu''${cpu}/online 2>/dev/null || true
        done
      fi
    '';
  };

  # Systemd service that runs the toggle script
  systemd.services.toggle-cpu-cores = {
    description = "Toggle CPU cores based on power source";
    after = ["sysinit.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/etc/power-management/toggle-cores.sh";
      RemainAfterExit = false;
    };
  };

  # udev rule: trigger the service when power supply changes
  services.udev.extraRules = ''
    # When AC adapter is plugged/unplugged, toggle CPU cores
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="${pkgs.systemd}/bin/systemctl start toggle-cpu-cores.service"
  '';

  # Also run at boot to set the correct initial state
  systemd.services.toggle-cpu-cores-boot = {
    description = "Set initial CPU core state based on power source";
    wantedBy = ["multi-user.target"];
    after = ["sysinit.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/etc/power-management/toggle-cores.sh";
      RemainAfterExit = true;
    };
  };

  # ---------------------------------------------------------------------------
  # Kernel Parameters for Power Management
  # ---------------------------------------------------------------------------
  boot.kernelParams = [
    # Enable Intel HWP (Hardware P-States) for better frequency scaling
    "intel_pstate=active"
  ];

  # Ensure cpufreq modules are available
  boot.kernelModules = [
    "cpufreq_powersave"
    "cpufreq_performance"
  ];
}
