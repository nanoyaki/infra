{
  flake.nixosModules.thelessone-jellyseerr =
    { lib, config, ... }:

    {
      systemd.services.seerr.wantedBy = lib.mkForce [ "server-services.target" ];
      services.seerr.enable = true;

      thelessone.caddy.vHost."jellyseerr.theless.one" = {
        proxy = { inherit (config.services.seerr) port; };
        pangolin.name = "Jellyseerr";
      };

      systemd.services.borgbackup-job-jellyseerr.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.jellyseerr = {
        repo = "/mnt/raid/borgbackup/jellyseerr";
        doInit = true;

        paths = "/var/lib/private/jellyseerr";

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
