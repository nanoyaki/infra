{ inputs, ... }:

{
  flake.nixosModules.sentinel-tangled =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    {
      imports = [
        inputs.tangled.nixosModules.knot
        inputs.avatar-server.nixosModules.avatar-server
      ];

      sops.secrets = {
        camo = { };
        "avatar-server/secret" = { };
      };

      sops.templates."avatar-server.env".file = pkgs.writeEnv "avatar-server.env.template" {
        AVATAR_SHARED_SECRET = config.sops.placeholder."avatar-server/secret";
      };

      services.tangled.knot = {
        enable = true;
        stateDir = "/var/lib/tangled";

        appviewEndpoint = "https://tangled.org";
        git.userEmail = "noreply@git.nanoyaki.space";
        server = {
          owner = "did:plc:majihettvb7ieflgmkvujecu";
          jetstreamEndpoint = "wss://jetstream2.us-east.bsky.network/subscribe";
          hostname = "knot.nanoyaki.space";
          listenAddr = "0.0.0.0:8001";
        };
      };

      services.tangled.avatar-server = {
        enable = false;
        port = 8003;
        environmentFile = config.sops.templates."avatar-server.env".path;
      };

      services.go-camo = {
        enable = false;
        listen = "0.0.0.0:8002";
        keyFile = config.sops.secrets.camo.path;
      };

      sentinel.caddy.host = {
        "knot.nanoyaki.space".proxy.port = 8001;
      }
      // lib.optionalAttrs config.services.go-camo.enable {
        "camo.nanoyaki.space".proxy.port = 8002;
      }
      // lib.optionalAttrs config.services.tangled.avatar-server.enable {
        "avatars.nanoyaki.space".proxy.port = 8003;
      };
    };
}
