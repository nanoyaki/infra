{
  flake.nixosModules.thelessone-radarr =
    { lib, config, ... }:

    {
      services.vopono.allowedTCPPorts = [ config.services.radarr.settings.server.port ];

      systemd.services.radarr.wantedBy = lib.mkForce [ "server-services.target" ];
      services.radarr = {
        enable = true;
        inherit (config.thelessone.arr) group;
      };

      thelessone.caddy.vHost."radarr.theless.one" = {
        proxy = {
          inherit (config.services.radarr.settings.server) port;
        };
        useTailnet = true;
      };

      thelessone.backups.radarr.paths = [ "/var/lib/radarr" ];
    };
}
