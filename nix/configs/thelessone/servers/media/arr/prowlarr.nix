{
  flake.nixosModules.thelessone-prowlarr =
    { lib, config, ... }:

    {
      services.vopono.systemd.services.prowlarr = [ config.services.prowlarr.settings.server.port ];

      systemd.services.prowlarr.wantedBy = lib.mkForce [ "server-services.target" ];
      services.prowlarr = {
        enable = true;
        openFirewall = true;
      };

      thelessone.caddy.vHost."prowlarr.theless.one" = {
        proxy = {
          host = config.services.vopono.voponoHost;
          inherit (config.services.prowlarr.settings.server) port;
        };
        useTailnet = true;
      };

      thelessone.backups.prowlarr.paths = [ "/var/lib/private/prowlarr" ];
    };
}
