{
  flake.nixosModules.thelessone-audiobookshelf =
    { config, ... }:

    {
      services.audiobookshelf = {
        enable = true;
        port = 46551;
      };

      fileSystems."/var/lib/audiobookshelf" = {
        device = "/mnt/raid/audiobookshelf";
        depends = [ "/mnt/raid" ];
        options = [ "bind" ];
        fsType = "none";
      };

      systemd.services.audiobookshelf.unitConfig.RequiresMountsFor = "/mnt/raid/audiobookshelf";

      thelessone.caddy.vHost."audiobookshelf.theless.one" = {
        proxy = {
          inherit (config.services.audiobookshelf) port;
        };
        pangolin.name = "Audiobookshelf";
      };

      systemd.services.borgbackup-job-audiobookshelf.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.audiobookshelf = {
        repo = "/mnt/raid/borgbackup/audiobookshelf";
        doInit = true;

        paths = "/mnt/raid/audiobookshelf";

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
