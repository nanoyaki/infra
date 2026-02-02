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

      thelessone.caddy.vHost."lidarr.theless.one" = {
        proxy = { inherit (config.services.lidarr.settings.server) port; };
        useVpn = true;
      };

      services.borgbackup.jobs.lidarr = {
        repo = "thelessone-borg@10.0.0.6:lidarr";
        environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
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
