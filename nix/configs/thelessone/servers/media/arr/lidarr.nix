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
        pangolin.name = "Lidarr";
      };

      systemd.services.borgbackup-job-lidarr.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.lidarr = {
        repo = "/mnt/raid/borgbackup/lidarr";
        doInit = true;

        paths = "/var/lib/lidarr";

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
