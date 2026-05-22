{
  flake.nixosModules.sentinel-federation =
    {
      pkgs,
      config,
      ...
    }:

    let
      plh = config.sops.placeholder;
    in

    {
      sops.secrets = {
        "pds/jwt" = { };
        "pds/admin-password" = { };
        "pds/k256-key" = { };
        "pds/smtp-dsn" = { };
      };

      sops.templates."bluesky-pds.env".file = pkgs.writeEnv "bluesky-pds.env.template" {
        PDS_JWT_SECRET = plh."pds/jwt";
        PDS_ADMIN_PASSWORD = plh."pds/admin-password";
        PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX = plh."pds/k256-key";
        PDS_EMAIL_SMTP_URL = plh."pds/smtp-dsn";
      };

      services.bluesky-pds = {
        enable = true;
        environmentFiles = [ config.sops.templates."bluesky-pds.env".path ];

        settings.PDS_PORT = 8000;
        settings.PDS_HOSTNAME = "pds.nanoyaki.space";
        settings.PDS_EMAIL_FROM_ADDRESS = "no-reply@theless.one";
      };

      sentinel.caddy.host."pds.nanoyaki.space".proxy.port = 8000;
    };
}
