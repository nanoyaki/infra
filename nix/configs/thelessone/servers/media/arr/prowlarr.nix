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
        pangolin.name = "Prowlarr";
      };

      systemd.services.borgbackup-job-prowlarr.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.prowlarr = {
        repo = "/mnt/raid/borgbackup/prowlarr";
        doInit = true;

        paths = "/var/lib/private/prowlarr";

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
