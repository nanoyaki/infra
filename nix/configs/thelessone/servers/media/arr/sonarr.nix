{
  flake.nixosModules.thelessone-sonarr =
    { config, ... }:

    {
      services.vopono.allowedTCPPorts = [ config.services.sonarr.settings.server.port ];

      systemd.services.sonarr.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.sonarr = {
        enable = true;
        inherit (config.thelessone.arr) group;
      };

      services.newt.blueprint.private-resources.sonarr = {
        name = "Sonarr";
        mode = "host";
        destination = "127.0.0.1";
        site = "utilized-olympic-marmot";
        tcp-ports = toString config.services.sonarr.settings.server.port;
        udp-ports = "";
        alias = "sonarr.theless.one";
        roles = [ "Arr-Admin" ];
      };

      systemd.services.borgbackup-job-sonarr.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.sonarr = {
        repo = "/mnt/raid/borgbackup/sonarr";
        doInit = true;

        paths = "/var/lib/sonarr";

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
