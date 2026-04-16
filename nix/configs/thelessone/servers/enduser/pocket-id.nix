{
  flake.nixosModules.thelessone-pocket-id =
    { config, ... }:

    let
      cfg = config.services.pocket-id;
    in

    {
      sops.secrets.pocket-id-encryption.owner = "pocket-id";

      services.pocket-id.enable = true;
      services.pocket-id.settings = {
        APP_URL = "https://id.theless.one";
        TRUST_PROXY = true;
        ANALYTICS_DISABLED = true;
        PORT = 1411;
        ENCRYPTION_KEY_FILE = config.sops.secrets.pocket-id-encryption.path;
      };

      services.newt.blueprint.public-resources.pocket-id = {
        name = "Pocket ID";
        protocol = "http";
        full-domain = "id.theless.one";
        targets = [
          {
            site = "utilized-olympic-marmot";
            hostname = "127.0.0.1";
            port = cfg.settings.PORT;
            method = "http";
          }
        ];
      };

      systemd.services.borgbackup-job-pocket-id.unitConfig.RequiresMountsFor = "/mnt/raid";
      services.borgbackup.jobs.pocket-id = {
        repo = "/mnt/raid/borgbackup/pocket-id";
        doInit = true;

        paths = cfg.dataDir;

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
