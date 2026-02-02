{
  flake.nixosModules.thelessnas-wireguard =
    { config, ... }:

    {
      sops.secrets.wg0 = { };

      networking.wg-quick.interfaces.wg0 = {
        address = [
          "10.101.0.4/32"
          "fd10::4/128"
        ];
        privateKeyFile = config.sops.secrets.wg0.path;

        peers = [
          {
            publicKey = "kdBOsYomUk9YEFs+qSsKHnbaMAL6r57IlkJoNweRKj8=";
            endpoint = "hanakretzer.de:51820";
            allowedIPs = [
              "10.101.0.1/32"
              "fd10::1/128"
            ];
            persistentKeepalive = 25;
          }
        ];
      };
    };
}
