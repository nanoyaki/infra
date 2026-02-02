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

      thelessone.caddy.vHost."radarr.theless.one" = {
        proxy = { inherit (config.services.radarr.settings.server) port; };
        useVpn = true;
      };

      services.borgbackup.jobs.radarr = {
        repo = "thelessone-borg@10.0.0.6:radarr";
        environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
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
