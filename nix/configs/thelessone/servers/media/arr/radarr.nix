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

      systemd.services.borgbackup-job-radarr.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.radarr = {
        repo = "/mnt/raid/borgbackup/radarr";
        doInit = true;

        paths = "/var/lib/radarr";

        encryption.mode = "none";
        compression = "zstd";

        startAt = "daily";
        persistentTimer = true;
        prune.keep = {
          within = "1d";
          daily = 14;
          weekly = 12;
          monthly = -1;
        };
      };
    };
}
