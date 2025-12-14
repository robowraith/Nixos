{pkgs, ...}: {
  programs.autorandr = {
    enable = true;

    hooks = {
      postswitch = {
        "herbstluftwm-monitors" = ''
          # Wait for X to settle
          sleep 1

          /usr/bin/env fish -c "set -Ux AUTORANDR_CURRENT_PROFILE $AUTORANDR_CURRENT_PROFILE"
          /usr/bin/env fish -c "set -Ux AUTORANDR_CURRENT_PROFILES $AUTORANDR_CURRENT_PROFILES"
          /usr/bin/env fish -c "set -Ux AUTORANDR_PROFILE_FOLDER $AUTORANDR_PROFILE_FOLDER"
          /usr/bin/env fish -c "set -Ux AUTORANDR_MONITORS $AUTORANDR_MONITORS"

          notify-send -i display "Display profile" "$AUTORANDR_CURRENT_PROFILE"

          exit 0
        '';
      };
    };

    profiles = {
      # "Old" office setup with LG 38"
      "LG38" = {
        fingerprint = {
          "HDMI-0" = "00ffffffffffff001e6dfb76072103000b1c010380572578eaca95a6554ea1260f5054256b807140818081c0a9c0b300d1c08100d1cfd8a40020f140686030207a006a6e3100001a85cf0020f140746030207a006a6e3100001a000000fd00384b1e7d36000a202020202020000000fc004c4720554c545241574944450a01f5020326f1230907074b100403011f1359da1205148301000065030c00200067d85dc4016c800040510020f140506030207a006a6e3100001ae4a770b8d1a02450906084006a6e3100001ae77c70a0d0a0295030203a006a6e3100001a000000ff003831314e54475936313036330a0000000000000000000000000000000000b6";
        };
        config = {
          HDMI-0 = {
            enable = true;
            primary = true;
            mode = "3840x1600";
            position = "0x0";
            rate = "75";
            rotate = "normal";
          };
        };
      };

      # "New" office setup with 55" 4K Monitor
      "Office_4K" = {
        fingerprint = {
          "DP-1" = "00ffffffffffff001e6dfb76072103000b1c010380572578eaca95a6554ea1260f5054256b807140818081c0a9c0b300d1c08100d1cfd8a40020f140686030207a006a6e3100001a85cf0020f140746030207a006a6e3100001a000000fd00384b1e7d36000a202020202020000000fc004c4720554c545241574944450a01f5020326f1230907074b100403011f1359da1205148301000065030c00200067d85dc4016c800040510020f140506030207a006a6e3100001ae4a770b8d1a02450906084006a6e3100001ae77c70a0d0a0295030203a006a6e3100001a000000ff003831314e54475936313036330a0000000000000000000000000000000000a6";
        };
        config = {
          DP-1 = {
            enable = true;
            primary = true;
            mode = "3840x2160";
            position = "0x0";
            rate = "120";
            rotate = "normal";
          };
        };
      };

      # Living room setup with 65" 4K TV
      "Gaming_4K" = {
        fingerprint = {
          "HDMI-0" = "00ffffffffffff001e6dfb76072103000b1c010380572578eaca95a6554ea1260f5054256b807140818081c0a9c0b300d1c08100d1cfd8a40020f140686030207a006a6e3100001a85cf0020f140746030207a006a6e3100001a000000fd00384b1e7d36000a202020202020000000fc004c4720554c545241574944450a01f5020326f1230907074b100403011f1359da1205148301000065030c00200067d85dc4016c800040510020f140506030207a006a6e3100001ae4a770b8d1a02450906084006a6e3100001ae77c70a0d0a0295030203a006a6e3100001a000000ff003831314e54475936313036330a0000000000000000000000000000000000a6";
        };
        config = {
          HDMI-0 = {
            enable = true;
            mode = "3840x2160";
            position = "0x0";
            rate = "60";
          };
        };
      };

      # Living room setup with 65" 4K TV
      "Gaming_1080p" = {
        fingerprint = {
          "HDMI-0" = "00ffffffffffff001e6dfb76072103000b1c010380572578eaca95a6554ea1260f5054256b807140818081c0a9c0b300d1c08100d1cfd8a40020f140686030207a006a6e3100001a85cf0020f140746030207a006a6e3100001a000000fd00384b1e7d36000a202020202020000000fc004c4720554c545241574944450a01f5020326f1230907074b100403011f1359da1205148301000065030c00200067d85dc4016c800040510020f140506030207a006a6e3100001ae4a770b8d1a02450906084006a6e3100001ae77c70a0d0a0295030203a006a6e3100001a000000ff003831314e54475936313036330a0000000000000000000000000000000000a6";
        };
        config = {
          HDMI-0 = {
            enable = true;
            primary = true;
            mode = "1920x1080";
            position = "0x0";
            rate = "60";
          };
        };
      };
    };
  };

  # Systemd service to auto-detect and switch on login/resume
  systemd.user.services.autorandr = {
    Unit = {
      Description = "Autorandr execution hook";
      After = ["graphical-session-pre.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.autorandr}/bin/autorandr --change --default laptop";
      RemainAfterExit = false;
    };

    Install.WantedBy = ["graphical-session.target"];
  };
}
