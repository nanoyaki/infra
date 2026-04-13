{
  flake.nixosModules.thelessone-jellyseerr =
    { config, ... }:

    {
      services.seerr.enable = true;

      services.newt.blueprint.private-resources.seerr = {
        name = "Seerr";
        mode = "host";
        destination = "127.0.0.1";
        site = "utilized-olympic-marmot";
        tcp-ports = toString config.services.seerr.port;
        udp-ports = "";
        alias = "jellyseerr.theless.one";
        roles = [ "Member" ];
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
