{ inputs, ... }:

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
      imports = [
        inputs.tangled.nixosModules.knot
        inputs.avatar-server.nixosModules.avatar-server
      ];

      sops.secrets = {
        camo = { };

        "pds/jwt" = { };
        "pds/admin-password" = { };
        "pds/k256-key" = { };
        "pds/smtp-dsn" = { };
        "avatar-server/secret" = { };
      };

      sops.templates."bluesky-pds.env".file = pkgs.writeEnv "bluesky-pds.env.template" {
        PDS_JWT_SECRET = plh."pds/jwt";
        PDS_ADMIN_PASSWORD = plh."pds/admin-password";
        PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX = plh."pds/k256-key";
        PDS_EMAIL_SMTP_URL = plh."pds/smtp-dsn";
      };

      sops.templates."avatar-server.env".file = pkgs.writeEnv "avatar-server.env.template" {
        AVATAR_SHARED_SECRET = plh."avatar-server/secret";
      };

      services.bluesky-pds = {
        enable = true;
        environmentFiles = [ config.sops.templates."bluesky-pds.env".path ];

        settings.PDS_PORT = 8000;
        settings.PDS_HOSTNAME = "pds.nanoyaki.space";
        settings.PDS_EMAIL_FROM_ADDRESS = "no-reply@theless.one";
      };

      services.tangled.knot = {
        enable = true;
        stateDir = "/var/lib/tangled";

        appviewEndpoint = "https://git.theless.one";
        git.userEmail = "noreply@git.nanoyaki.space";
        server = {
          owner = "did:plc:majihettvb7ieflgmkvujecu";
          jetstreamEndpoint = "wss://jetstream2.us-east.bsky.network/subscribe";
          hostname = "knot.nanoyaki.space";
          listenAddr = "0.0.0.0:8001";
        };
      };

      services.tangled.avatar-server = {
        enable = true;
        port = 8003;
        environmentFile = config.sops.templates."avatar-server.env".path;
      };

      services.go-camo = {
        enable = true;
        listen = "0.0.0.0:8002";
        keyFile = config.sops.secrets.camo.path;
      };

      services.traefik.dynamicConfigOptions = {
        http.routers = {
          pds = {
            rule = "Host(`pds.nanoyaki.space`)";
            entryPoints = [ "websecure" ];
            service = "pds";
            tls.certResolver = "letsencrypt";
          };

          knot = {
            rule = "Host(`knot.nanoyaki.space`)";
            entryPoints = [ "websecure" ];
            service = "knot";
            tls.certResolver = "letsencrypt";
          };

          camo = {
            rule = "Host(`camo.nanoyaki.space`)";
            entryPoints = [ "websecure" ];
            service = "camo";
            tls.certResolver = "letsencrypt";
          };

          avatars = {
            rule = "Host(`avatars.nanoyaki.space`)";
            entryPoints = [ "websecure" ];
            service = "avatars";
            tls.certResolver = "letsencrypt";
          };
        };

        http.services = {
          pds.loadBalancer.servers = [
            { url = "http://127.0.0.1:8000"; }
          ];

          knot.loadBalancer.servers = [
            { url = "http://127.0.0.1:8001"; }
          ];

          camo.loadBalancer.servers = [
            { url = "http://127.0.0.1:8002"; }
          ];

          avatars.loadBalancer.servers = [
            { url = "http://127.0.0.1:8003"; }
          ];
        };
      };
    };
}
