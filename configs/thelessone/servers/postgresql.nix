{
  lib,
  config,
  ...
}:

{
  services.borgbackup.jobs.postgresql-all = {
    repo = "thelessone-borg@10.0.0.6:postgresql-all";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
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
}
