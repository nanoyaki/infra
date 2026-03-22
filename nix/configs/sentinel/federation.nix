{ inputs, ... }:

{
  flake.nixosModules.sentinel-federation =
    {
      # lib,
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
        # inputs.tangled.nixosModules.knotmirror
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

      # The mirror is far too heavy to self-host on this server

      # systemd.services.knotmirror = {
      #   serviceConfig.User = "knotmirror";
      #   serviceConfig.Group = "knotmirror";

      #   unitConfig = {
      #     MemoryMax = "1536M";
      #     CPUQuota = "40%";
      #     CPUQuotaPeriodSec = "500ms";
      #     AllowedCPUs = "2";
      #   };
      # };
      # systemd.services.tap-knotmirror = {
      #   serviceConfig.User = "knotmirror-tap";
      #   serviceConfig.Group = "knotmirror-tap";

      #   unitConfig = {
      #     MemoryMax = "1536M";
      #     CPUQuota = "40%";
      #     CPUQuotaPeriodSec = "750ms";
      #     AllowedCPUs = "2";
      #   };
      # };

      # services.tangled.knotmirror = {
      #   package = pkgs.knotmirror;
      #   enable = true;
      #   fullNetwork = true;

      #   listenAddr = "0.0.0.0:8004";
      #   hostname = "knotmirror.nanoyaki.space";
      #   atpRelayUrl = "https://relay1.us-east.bsky.network";
      #   dbUrl = "postgresql:///knotmirror?host=/run/postgresql";
      #   tap.dbUrl = "postgresql:///knotmirror-tap?host=/run/postgresql";
      # };

      # users.groups.knotmirror-tap = { };
      # users.groups.knotmirror = { };

      # users.users.knotmirror-tap = {
      #   description = "Knotmirror-tap service user";
      #   isSystemUser = true;
      #   group = "knotmirror-tap";
      # };
      # users.users.knotmirror = {
      #   description = "Knotmirror service user";
      #   isSystemUser = true;
      #   group = "knotmirror";
      # };

      # services.postgresql = {
      #   enable = lib.mkDefault true;
      #   ensureDatabases = [
      #     "knotmirror-tap"
      #     "knotmirror"
      #   ];
      #   ensureUsers = [
      #     {
      #       name = "knotmirror-tap";
      #       ensureDBOwnership = true;
      #     }
      #     {
      #       name = "knotmirror";
      #       ensureDBOwnership = true;
      #     }
      #   ];
      # };

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

      services.caddy.virtualHosts."pds.nanoyaki.space" = {
        useACMEHost = "nanoyaki.space";
        extraConfig = ''
          reverse_proxy 127.0.0.1:8000
        '';
      };

      services.caddy.virtualHosts."knot.nanoyaki.space" = {
        useACMEHost = "nanoyaki.space";
        extraConfig = ''
          reverse_proxy 127.0.0.1:8001
        '';
      };

      services.caddy.virtualHosts."camo.nanoyaki.space" = {
        useACMEHost = "nanoyaki.space";
        extraConfig = ''
          reverse_proxy 127.0.0.1:8002
        '';
      };

      services.caddy.virtualHosts."avatars.nanoyaki.space" = {
        useACMEHost = "nanoyaki.space";
        extraConfig = ''
          reverse_proxy 127.0.0.1:8003
        '';
      };

      # services.caddy.virtualHosts."knotmirror.nanoyaki.space" = {
      #   useACMEHost = "nanoyaki.space";
      #   extraConfig = ''
      #     reverse_proxy 127.0.0.1:8004
      #   '';
      # };
    };
}
