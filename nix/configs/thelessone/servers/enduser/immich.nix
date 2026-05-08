{
  flake.nixosModules.thelessone-immich =
    { lib, config, ... }:

    {
      systemd.services.immich-server.wantedBy = lib.mkForce [ "server-services.nix" ];
      systemd.services.immich-machine-learning.wantedBy = lib.mkForce [ "server-services.nix" ];
      services.immich = {
        enable = true;
        accelerationDevices = [ "/dev/dri/renderD128" ];
      };

      users.users.${config.services.immich.user}.extraGroups = [
        "video"
        "render"
      ];

      systemd.services.immich-public-proxy.wantedBy = lib.mkForce [ "server-services.nix" ];
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

      thelessone.caddy.vHost."immich.theless.one" = {
        proxy = { inherit (config.services.immich) port; };
        pangolin.name = "Immich";
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
