{
  flake.nixosModules.sentinel-traefik =
    { pkgs, ... }:

    {
      # Tunneled ports
      networking.firewall.allowedTCPPorts = [
        22 # Forgejo SSH

        25565 # Minecraft
        7777 # SCP:SL
        2456 # Valheim
      ];

      services.caddy.virtualHosts.":8007".extraConfig = ''
        root * ${pkgs.theless-dot-one}
        file_server
      '';

      services.traefik = {
        staticConfigOptions.entryPoints = {
          tcp-22.address = ":22/tcp";

          tcp-25565.address = ":25565/tcp";
          tcp-7777.address = ":7777/tcp";
          tcp-2456.address = ":2456/tcp";
        };

        dynamicConfigOptions = {
          http.middlewares.test-errors.errors = {
            status = [
              "401"
              "403"
              "404"
              "502"
              "503"
            ];
            service = "error-handler";
            query = "/{status}.html";
          };

          http.services.error-handler.loadBalancer.servers = [
            { url = "http://127.0.0.1:8007"; }
          ];

          tls.certificates = [
            {
              certFile = "/var/lib/acme/theless.one/cert.pem";
              keyFile = "/var/lib/acme/theless.one/key.pem";
            }
            {
              certFile = "/var/lib/acme/nanoyaki.space/cert.pem";
              keyFile = "/var/lib/acme/nanoyaki.space/key.pem";
            }
          ];
        };
      };
    };
}
