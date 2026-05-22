{
  flake.nixosModules.thelessone-pocket-id =
    { lib, config, ... }:

    let
      cfg = config.services.pocket-id;
    in

    {
      sops.secrets.pocket-id-encryption.owner = "pocket-id";

      systemd.services.pocket-id.wantedBy = lib.mkForce [ "server-services.target" ];
      services.pocket-id.enable = true;
      services.pocket-id.settings = {
        APP_URL = "https://id.theless.one";
        TRUST_PROXY = true;
        ANALYTICS_DISABLED = true;
        PORT = 1411;
        ENCRYPTION_KEY_FILE = config.sops.secrets.pocket-id-encryption.path;
      };

      thelessone.caddy.vHost."id.theless.one" = {
        proxy.port = cfg.settings.PORT;
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
