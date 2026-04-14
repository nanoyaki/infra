{
  flake.nixosModules.thelessone-kavita =
    { config, ... }:

    {
      sops.secrets.kavita = { };

      services.kavita = {
        enable = true;
        tokenKeyFile = config.sops.secrets.kavita.path;
        settings.Port = 3300;
      };

      thelessone.caddy.vHost."books.theless.one" = {
        proxy.port = config.services.kavita.settings.Port;
        pangolin.name = "Kavita";
      };

      systemd.services.borgbackup-job-kavita.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.kavita = {
        repo = "/mnt/raid/borgbackup/kavita";
        doInit = true;

        paths = config.services.kavita.dataDir;

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
