{pkgs, ...}: {
  home.packages = with pkgs; [
    vivaldi
  ];

  programs.vivaldi = {
    enable = true;
    extensions = [
      # Cookie AutoDelete
      # https://chromewebstore.google.com/detail/cookie-autodelete/fhcgjolkccmbidfldomjliifgaodjagh
      {id = "fhcgjolkccmbidfldomjliifgaodjagh";}
      # I still don`t care about cookies
      # https://chromewebstore.google.com/detail/i-still-dont-care-about-c/edibdbjcniadpccecjdfdjjppcpchdlm
      {id = "edibdbjcniadpccecjdfdjjppcpchdlm";}
      # KeePassXC Browser
      # https://chromewebstore.google.com/detail/keepassxc-browser/oboonakemofpalcgghocfoadofidjkkk
      {id = "oboonakemofpalcgghocfoadofidjkkk";}
      # Vimium
      # https://chromewebstore.google.com/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb
      {id = "dbepggeogbaibhgnhhndojpepiihcmeb";}
    ];

    nativeMessagingHosts = [
      (pkgs.writeTextFile {
        name = "keepassxc-chromium-native-host";
        destination = "/etc/chromium/native-messaging-hosts/org.keepassxc.keepassxc_browser.json";
        text = builtins.toJSON {
          name = "org.keepassxc.keepassxc_browser";
          description = "KeePassXC integration with native messaging support";
          path = "${pkgs.keepassxc}/bin/keepassxc-proxy";
          type = "stdio";
          allowed_origins = [
            "chrome-extension://oboonakemofpalcgghocfoadofidjkkk/"
          ];
        };
      })
    ];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "vivaldi-stable.desktop";
      "x-scheme-handler/http" = "vivaldi-stable.desktop";
      "x-scheme-handler/https" = "vivaldi-stable.desktop";
      "x-scheme-handler/about" = "vivaldi-stable.desktop";
      "x-scheme-handler/unknown" = "vivaldi-stable.desktop";
    };
  };
}
