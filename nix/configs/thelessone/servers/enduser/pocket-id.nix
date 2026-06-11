{
  flake.nixosModules.thelessone-pocket-id =
    { lib, config, ... }:

    let
      inherit (config) prt dmn sec;

      cfg = config.services.pocket-id;
    in

    {
      prt.pocket-id = 8009;
      dmn.pocket-id = "id.theless.one";

      sec.pocket-id-encryption.owner = "pocket-id";

      systemd.services.pocket-id.wantedBy = lib.mkForce [ "server-services.target" ];
      services.pocket-id.enable = true;
      services.pocket-id.settings = {
        APP_URL = "https://${dmn.pocket-id}";
        TRUST_PROXY = true;
        ANALYTICS_DISABLED = true;
        PORT = prt.pocket-id;
        ENCRYPTION_KEY_FILE = sec.pocket-id-encryption.path;
      };

      thelessone.caddy.vHost.${dmn.pocket-id}.proxy.port = prt.pocket-id;

      thelessone.backups.pocket-id.paths = [ cfg.dataDir ];
    };
}
