{
  flake.nixosModules.thelessone-immich =
    { config, ... }:

    {
      services.immich = {
        enable = true;
        accelerationDevices = [ "/dev/dri/renderD128" ];
      };

      users.users.${config.services.immich.user}.extraGroups = [
        "video"
        "render"
      ];

      services.immich-public-proxy = {
        enable = true;
        immichUrl = "http://localhost:2283";
        port = 19220;
        settings.allowDownloadAll = 1;
      };

      services.newt.blueprint.public-resources.immich-public-proxy = {
        name = "Immich Public Proxy";
        protocol = "http";
        full-domain = "images.theless.one";
        targets = [
          {
            site = "utilized-olympic-marmot";
            hostname = "127.0.0.1";
            inherit (config.services.immich-public-proxy) port;
            method = "http";
            path = "/";
            path-match = "prefix";
          }
        ];
      };

      services.newt.blueprint.private-resources.immich = {
        name = "Immich";
        mode = "host";
        destination = "127.0.0.1";
        site = "utilized-olympic-marmot";
        tcp-ports = toString config.services.immich.port;
        udp-ports = "";
        alias = "immich.theless.one";
        roles = [ "Member" ];
      };

      systemd.services.borgbackup-job-immich.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.immich = {
        repo = "/mnt/raid/borgbackup/immich";
        doInit = true;

        paths = "/var/lib/immich";

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
