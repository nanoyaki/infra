{ inputs, ... }:

{
  flake.nixosModules.sentinel-tangled =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (config)
        prt
        dmn
        tpl
        plh
        sec
        ;
    in

    {
      imports = [
        inputs.tangled.nixosModules.knot
        inputs.avatar-server.nixosModules.avatar-server
      ];

      sec.camo = { };
      sec."avatar-server/secret" = { };

      tpl."avatar-server.env".file = pkgs.writeEnv "avatar-server.env.template" {
        AVATAR_SHARED_SECRET = plh."avatar-server/secret";
      };

      prt = {
        knot = 8001;
        camo = 8002;
        avatar-server = 8003;
      };

      dmn = {
        knot = "knot.nanoyaki.space";
        camo = "camo.nanoyaki.space";
        avatar-server = "avatars.nanoyaki.space";
      };

      services.tangled.knot = {
        enable = true;
        stateDir = "/var/lib/tangled";

        appviewEndpoint = "https://tangled.org";
        git.userEmail = "noreply@git.nanoyaki.space";
        server = {
          owner = "did:plc:majihettvb7ieflgmkvujecu";
          jetstreamEndpoint = "wss://jetstream2.us-east.bsky.network/subscribe";
          hostname = dmn.knot;
          listenAddr = "0.0.0.0:${toString prt.knot}";
        };
      };

      services.go-camo = {
        enable = false;
        listen = "0.0.0.0:${toString prt.camo}";
        keyFile = sec.camo.path;
      };

      services.tangled.avatar-server = {
        enable = false;
        port = prt.avatar-server;
        environmentFile = tpl."avatar-server.env".path;
      };

      sentinel.caddy.host = {
        ${dmn.knot}.proxy.port = prt.knot;
      }
      // lib.optionalAttrs config.services.go-camo.enable {
        ${dmn.camo}.proxy.port = prt.camo;
      }
      // lib.optionalAttrs config.services.tangled.avatar-server.enable {
        ${dmn.avatar-server}.proxy.port = prt.avatar-server;
      };
    };
}
