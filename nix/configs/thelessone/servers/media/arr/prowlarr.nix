{
  flake.nixosModules.thelessone-prowlarr =
    { config, ... }:

    {
      services.vopono.systemd.services.prowlarr = [ config.services.prowlarr.settings.server.port ];

      services.prowlarr = {
        enable = true;
        openFirewall = true;
      };

      services.newt.blueprint.private-resources.prowlarr = {
        name = "Prowlarr";
        mode = "host";
        destination = config.services.vopono.voponoHost;
        site = "utilized-olympic-marmot";
        tcp-ports = toString config.services.prowlarr.settings.server.port;
        udp-ports = "";
        alias = "prowlarr.theless.one";
        roles = [ "Arr-Admin" ];
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
