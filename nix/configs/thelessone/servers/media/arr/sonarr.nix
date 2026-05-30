{
  flake.nixosModules.thelessone-sonarr =
    { lib, config, ... }:

    {
      services.vopono.allowedTCPPorts = [ config.services.sonarr.settings.server.port ];

      systemd.services.sonarr.wantedBy = lib.mkForce [ "server-services.target" ];
      services.sonarr = {
        enable = true;
        inherit (config.thelessone.arr) group;
      };

      thelessone.caddy.vHost."sonarr.theless.one" = {
        proxy = {
          inherit (config.services.sonarr.settings.server) port;
        };
        useTailnet = true;
      };

      thelessone.backups.sonarr.paths = [ "/var/lib/sonarr" ];
    };
}
