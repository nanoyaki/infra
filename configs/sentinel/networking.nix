{ config, ... }:

{
  sops.secrets.wg0 = { };

  networking.wireguard.interfaces.wg0 = {
    ips = [
      # "100.64.64.7/32" CGNAT
      "fd64::7/128"
    ];
    privateKeyFile = config.sops.secrets.wg0.path;

    peers = [
      {
        publicKey = "JB0jviICHpiTm1PYjm4+FCWCPLAjU/NZBm6tRO6/XGY=";
        endpoint = "at01.theless.one:51820";
        allowedIPs = [
          # "100.64.64.1/32" CGNAT
          "fd64::1/128"
        ];
        persistentKeepalive = 25;
      }
    ];
  };

  networking.firewall.trustedInterfaces = [ "wg0" ];
}
