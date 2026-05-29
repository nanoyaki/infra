{
  flake.nixosModules.thelessone-backups =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (lib)
        mkOption
        types
        mapAttrs
        recursiveUpdate
        ;
    in

    {
      options.thelessone.backups = mkOption {
        type = types.attrsOf types.anything;
        default = { };
      };

      config = {
        services.restic.backups = mapAttrs (
          name: cfg:
          recursiveUpdate cfg {
            repository = "/mnt/raid/backup.d/${name}";
            package = pkgs.rustic;

            timerConfig = {
              OnCalendar = "daily";
              Persistent = true;
            }
            // cfg.timerConfig or { };

            pruneOpts =
              cfg.pruneOpts or [
                "--keep-daily 7"
                "--keep-weekly 4"
                "--keep-monthly 12"
                "--keep-yearly 2"
              ];
          }
        ) config.thelessone.backups;

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
    };
}
