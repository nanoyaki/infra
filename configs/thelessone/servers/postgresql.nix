{ config, pkgs, ... }:

{
  sops.secrets."restic/postgresql".owner = "postgres";

  config'.restic.backups.postgresql = {
    repository = "/mnt/raid/backups/postgresql";
    passwordFile = config.sops.secrets."restic/postgresql".path;

    user = "postgres";
    backupPrepareCommand =
      (pkgs.writeScript "postgresql-prepare-backup" ''
        ${config.services.postgresql.package}/bin/pg_dumpall -U postgres -W | ${pkgs.gzip}/bin/gzip > backup.sql.gz
      '').outPath;
    basePath = "${config.services.postgresql.dataDir}/backup.sql.gz";

    timerConfig.OnCalendar = "daily";
  };
}
