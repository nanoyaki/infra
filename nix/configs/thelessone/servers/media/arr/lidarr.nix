{
  flake.nixosModules.thelessone-lidarr =
    { config, ... }:

    {
      services.vopono.allowedTCPPorts = [ config.services.lidarr.settings.server.port ];

      systemd.services.lidarr.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.lidarr = {
        enable = true;
        inherit (config.thelessone.arr) group;
      };

      services.newt.blueprint.private-resources.lidarr = {
        name = "Lidarr";
        mode = "host";
        destination = "127.0.0.1";
        site = "utilized-olympic-marmot";
        tcp-ports = toString config.services.lidarr.settings.server.port;
        udp-ports = "";
        alias = "lidarr.theless.one";
        roles = [ "Arr-Admin" ];
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
