{
  flake.nixosModules.thelessone-lidarr =
    { lib, config, ... }:

    {
      services.vopono.allowedTCPPorts = [ config.services.lidarr.settings.server.port ];

      systemd.services.lidarr.wantedBy = lib.mkForce [ "server-services.target" ];
      services.lidarr = {
        enable = true;
        inherit (config.thelessone.arr) group;
      };

      thelessone.caddy.vHost."lidarr.theless.one" = {
        proxy = {
          inherit (config.services.lidarr.settings.server) port;
        };
        useTailnet = true;
      };

      thelessone.backups.lidarr.paths = [ "/var/lib/lidarr" ];
    };
}
