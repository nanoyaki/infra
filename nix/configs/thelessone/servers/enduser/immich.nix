{
  flake.nixosModules.thelessone-immich =
    { lib, config, ... }:

    {
      systemd.services.immich-server.wantedBy = lib.mkForce [ "server-services.target" ];
      systemd.services.immich-machine-learning.wantedBy = lib.mkForce [ "server-services.target" ];
      services.immich = {
        enable = true;
        accelerationDevices = [ "/dev/dri/renderD128" ];
      };

      users.users.${config.services.immich.user}.extraGroups = [
        "video"
        "render"
      ];

      systemd.services.immich-public-proxy.wantedBy = lib.mkForce [ "server-services.target" ];
      services.immich-public-proxy = {
        enable = true;
        immichUrl = "http://localhost:2283";
        port = 19220;
        settings.allowDownloadAll = 1;
      };

      thelessone.caddy.vHost."images.theless.one".proxy = {
        inherit (config.services.immich-public-proxy) port;
      };

      thelessone.caddy.vHost."immich.theless.one" = {
        proxy = { inherit (config.services.immich) port; };
        useTailnet = true;
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
