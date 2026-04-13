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

      services.newt.blueprint.private-resources.audiobookshelf = {
        name = "Audiobookshelf";
        mode = "host";
        destination = "127.0.0.1";
        site = "utilized-olympic-marmot";
        tcp-ports = toString config.services.audiobookshelf.port;
        udp-ports = "";
        alias = "audiobookshelf.theless.one";
        roles = [ "Member" ];
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
