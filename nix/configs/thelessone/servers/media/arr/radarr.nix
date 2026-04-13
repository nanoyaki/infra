{
  flake.nixosModules.thelessone-radarr =
    { config, ... }:

    {
      services.vopono.allowedTCPPorts = [ config.services.radarr.settings.server.port ];

      systemd.services.radarr.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.radarr = {
        enable = true;
        inherit (config.thelessone.arr) group;
      };

      services.newt.blueprint.private-resources.radarr = {
        name = "Radarr";
        mode = "host";
        destination = "127.0.0.1";
        site = "utilized-olympic-marmot";
        tcp-ports = toString config.services.radarr.settings.server.port;
        udp-ports = "";
        alias = "radarr.theless.one";
        roles = [ "Arr-Admin" ];
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
