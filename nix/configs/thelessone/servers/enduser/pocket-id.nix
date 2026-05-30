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

      thelessone.backups.pocket-id.paths = [ cfg.dataDir ];
    };
}
