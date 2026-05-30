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
        mapAttrs'
        ;

      mkBackup =
        name: cfg:

        cfg
        // {
          initialize = true;
          repository = "/mnt/raid/backup.d/${name}";
          package = pkgs.rustic;

          passwordFile = config.sops.secrets.restic-encryption.path;

          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
            RandomizedDelaySec = "30min";
          }
          // cfg.timerConfig or { };

          checkOpts =
            cfg.checkOpts or [
              "latest"
            ];

          pruneOpts =
            cfg.pruneOpts or [
              "--keep-daily 7"
              "--keep-weekly 4"
              "--keep-monthly 3"
            ];
        };

      mkMountRequirement = name: _: {
        name = "restic-backups-${name}";
        value.requires = [ "mnt-raid.mount" ];
        value.after = [ "mnt-raid.mount" ];
      };
    in

    {
      options.thelessone.backups = mkOption {
        type = types.attrsOf types.anything;
        default = { };
      };

      config = {
        sops.secrets.restic-encryption = { };
        services.restic.backups = mapAttrs mkBackup config.thelessone.backups;
        systemd.services = mapAttrs' mkMountRequirement config.thelessone.backups;
      };
    };
}
