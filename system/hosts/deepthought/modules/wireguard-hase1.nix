{config, ...}: {
  # WireGuard to the 42he devbox host hase1 (ansible #1877). The peer reaches only its own
  # Incus container (hase1-joachim, SSH only), so only the container net is routed here.
  # The role allows one peer per environment: enable this on deepthought only.
  sops.secrets.wireguard_hase1_private = {};

  networking.wg-quick.interfaces.hase1 = {
    address = ["10.250.1.4/32"];
    privateKeyFile = config.sops.secrets.wireguard_hase1_private.path;
    peers = [
      {
        # Server key: `sudo wg show wg0 public-key` on hase1.
        publicKey = "bUuKtmxStyUdRJmHOZa5jHn1LhKuC5nkOoUkIw1t63U=";
        endpoint = "hase1.42he.com:51820";
        allowedIPs = ["10.250.0.0/24"];
        persistentKeepalive = 25;
      }
    ];
  };
}
