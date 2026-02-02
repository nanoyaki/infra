{
  flake.nixosModules.thelessone-immich =
    { config, ... }:

    let
      domain = "immich.theless.one";
    in

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

      thelessone.caddy.vHost."images.theless.one".proxy = {
        inherit (config.services.immich-public-proxy) port;
      };

      thelessone.caddy.vHost.${domain} = {
        proxy = { inherit (config.services.immich) port; };
        useVpn = true;
      };

      services.borgbackup.jobs.immich = {
        repo = "thelessone-borg@10.0.0.6:immich";
        environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
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
