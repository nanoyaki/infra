{
  flake.nixosModules.sentinel-federation =
    {
      pkgs,
      config,
      ...
    }:

    let
      inherit (config)
        prt
        dmn
        plh
        tpl
        ;
    in

    {
      prt.bsky-pds = 8000;
      dmn.bsky-pds = "pds.nanoyaki.space";

      sec = {
        "pds/jwt" = { };
        "pds/admin-password" = { };
        "pds/k256-key" = { };
        "pds/smtp-dsn" = { };
      };

      tpl."bluesky-pds.env".file = pkgs.writeEnv "bluesky-pds.env.template" {
        PDS_JWT_SECRET = plh."pds/jwt";
        PDS_ADMIN_PASSWORD = plh."pds/admin-password";
        PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX = plh."pds/k256-key";
        PDS_EMAIL_SMTP_URL = plh."pds/smtp-dsn";
      };

      services.bluesky-pds = {
        enable = true;
        environmentFiles = [ tpl."bluesky-pds.env".path ];

        settings.PDS_PORT = prt.bsky-pds;
        settings.PDS_HOSTNAME = dmn.bsky-pds;
        settings.PDS_EMAIL_FROM_ADDRESS = "no-reply@${dmn.self}";
      };

      sentinel.caddy.host.${dmn.bsky-pds}.proxy.port = prt.bsky-pds;
    };
}
