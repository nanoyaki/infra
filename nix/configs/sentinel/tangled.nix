{ inputs, ... }:

{
  flake.nixosModules.sentinel-tangled =
    {
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
    };
}
