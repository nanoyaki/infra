{
  flake.nixosModules.thelessone-papra =
    { config, ... }:

    let
      cfg = config.services.papra;
    in

    {
      services.papra.enable = true;
      services.papra.environment = {
        SERVER_SERVE_PUBLIC_DIR = true;
        PORT = 1221;
        DATABASE_URL = "file:/var/lib/papra/db.sqlite";
        DOCUMENT_STORAGE_FILESYSTEM_ROOT = "/var/lib/papra/local-documents";
        APP_BASE_URL = "https://papra.theless.one";
      };

      thelessone.caddy.vHost."papra.theless.one" = {
        proxy.port = cfg.environment.PORT;
        pangolin.name = "Papra";
      };

      systemd.services.borgbackup-job-papra.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.papra = {
        repo = "/mnt/raid/borgbackup/papra";
        doInit = true;

        paths = "/var/lib/papra";

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
