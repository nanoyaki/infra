{
  flake.nixosModules.sumire-coturn =
    { config, ... }:

    let
      inherit (config) sec tpl;

      cfg = config.services.coturn;
    in

    {
      sec."coturn/auth-secret" = {
        owner = "turnserver";
        group = "turn-secret";
        mode = "440";
      };

      networking.firewall = with cfg; {
        allowedUDPPorts = [ tls-listening-port ];
        allowedTCPPorts = [ tls-listening-port ];
        allowedUDPPortRanges = [
          {
            from = min-port;
            to = max-port;
          }
        ];
      };

      users.groups.turn-secret = { };
      users.users.turnserver.extraGroups = [ "turn-secret" ];

      services.coturn = {
        enable = true;
        no-cli = true;

        realm = "turn.serdexmethylpheni.date";
        cert = "${config.security.acme.certs.${cfg.realm}.directory}/full.pem";
        pkey = "${config.security.acme.certs.${cfg.realm}.directory}/key.pem";
        static-auth-secret-file = sec."coturn/auth-secret".path;

        listening-ips = [
          "5.175.180.4"
          "2a0f:6284:4300:101::110d"
        ];
        listening-port = 3478;
        tls-listening-port = 5349;
        min-port = 50201;
        max-port = 51200;

        extraConfig = ''
          denied-peer-ip=10.0.0.0-10.255.255.255
          denied-peer-ip=192.168.0.0-192.168.255.255
          denied-peer-ip=172.16.0.0-172.31.255.255

          no-multicast-peers
          denied-peer-ip=0.0.0.0-0.255.255.255
          denied-peer-ip=100.64.0.0-100.127.255.255
          denied-peer-ip=127.0.0.0-127.255.255.255
          denied-peer-ip=169.254.0.0-169.254.255.255
          denied-peer-ip=192.0.0.0-192.0.0.255
          denied-peer-ip=192.0.2.0-192.0.2.255
          denied-peer-ip=192.88.99.0-192.88.99.255
          denied-peer-ip=198.18.0.0-198.19.255.255
          denied-peer-ip=198.51.100.0-198.51.100.255
          denied-peer-ip=203.0.113.0-203.0.113.255
          denied-peer-ip=240.0.0.0-255.255.255.255
          denied-peer-ip=::1
          denied-peer-ip=64:ff9b::-64:ff9b::ffff:ffff
          denied-peer-ip=::ffff:0.0.0.0-::ffff:255.255.255.255
          denied-peer-ip=100::-100::ffff:ffff:ffff:ffff
          denied-peer-ip=2001::-2001:1ff:ffff:ffff:ffff:ffff:ffff:ffff
          denied-peer-ip=2002::-2002:ffff:ffff:ffff:ffff:ffff:ffff:ffff
          denied-peer-ip=fc00::-fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
          denied-peer-ip=fe80::-febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff

          # special case the turn server itself so that client->TURN->TURN->client flows work
          allowed-peer-ip=5.175.180.4

          user-quota=12
          total-quota=1200

          syslog
        '';
      };

      security.acme.certs.${cfg.realm} = {
        environmentFile = tpl."porkbun.env".path;
        reloadServices = [ "coturn.service" ];
        group = "turnserver";
      };
    };
}
