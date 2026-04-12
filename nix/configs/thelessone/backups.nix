{
  flake.nixosModules.thelessone-backups =
    { lib, config, ... }:

    {
      sops.secrets.id_borg_thelessone = { };

      systemd.services.borgbackup-job-postgresql-all.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.postgresql-all = {
        repo = "/mnt/raid/borgbackup/postgres";
        doInit = true;

        user = "postgres";
        group = "postgres";
        dumpCommand = lib.getExe' config.services.postgresql.package "pg_dumpall";

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
