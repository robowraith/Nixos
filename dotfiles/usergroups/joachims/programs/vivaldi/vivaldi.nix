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
  };
}
