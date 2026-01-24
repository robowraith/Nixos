{pkgs, ...}: {
  systemd.user.services.autorandr = {
    Unit = {
      Description = "Autorandr execution hook";
      After = ["graphical-session-pre.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.autorandr}/bin/autorandr --change";
      RemainAfterExit = false;
    };

    Install.WantedBy = ["graphical-session.target"];
  };

  systemd.user.services.fix-monitor-on-resume = {
    Unit = {
      Description = "Fix monitor on resume";
      After = ["suspend.target" "hibernate.target" "hybrid-sleep.target"];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "fix-monitor-on-resume" ''
        #!/bin/sh
        export DISPLAY=:0
        export XAUTHORITY=/home/joachim/.Xauthority
        sleep 5
        ${pkgs.xrandr}/bin/xrandr --output HDMI-0 --off
        sleep 1
        ${pkgs.autorandr}/bin/autorandr --change
        sleep 1
        ${pkgs.xrandr}/bin/xrandr --output HDMI-0 --auto
        sleep 1
        ${pkgs.autorandr}/bin/autorandr --change
      ''}";
    };

    Install.WantedBy = ["suspend.target" "hibernate.target" "hybrid-sleep.target"];
  };
}
