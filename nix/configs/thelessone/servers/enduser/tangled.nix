{ inputs, ... }:

{
  # Tangled is nowhere close to mature
  # enough yet even for basic usage
  flake.nixosModules.thelessone-tangledAppview =
    {
      lib,
      config,
      pkgs,
      ...
    }:

    let
      inherit (config)
        dmn
        prt
        plh
        tpl
        ;

      sentinel = inputs.self.nixosConfigurations.sentinel.config;
    in

    {
      imports = [
        inputs.tangled.nixosModules.appview
        inputs.tangled.nixosModules.spindle
      ];

      prt.tangled-appview = 8012;
      prt.tangled-spindle = 8013;
      dmn.git = lib.mkDefault "git.theless.one";
      dmn.tangled-spindle = "spindle.theless.one";

      sec = {
        "tangled/camo" = { };
        "tangled/client-secret" = { };
        "tangled/client-kid" = { };
        "tangled/cookie-secret" = { };
        "tangled/app-password" = { };
        "tangled/alt-app-password" = { };
        "tangled/pds-admin-password" = { };
        "tangled/avatar-secret" = { };
      };

      tpl."tangled-appview.env".file = pkgs.writeEnv "tangled-appview.env.template" {
        TANGLED_CAMO_SHARED_SECRET = plh."tangled/camo";
        TANGLED_OAUTH_CLIENT_SECRET = plh."tangled/client-secret";
        TANGLED_OAUTH_CLIENT_KID = plh."tangled/client-kid";
        TANGLED_COOKIE_SECRET = plh."tangled/cookie-secret";
        TANGLED_APP_PASSWORD = plh."tangled/app-password";
        TANGLED_ALT_APP_PASSWORD = plh."tangled/alt-app-password";
        TANGLED_PDS_ADMIN_SECRET = plh."tangled/pds-admin-password";
        TANGLED_AVATAR_SHARED_SECRET = plh."tangled/avatar-secret";
      };

      systemd.services.appview.environment.TANGLED_KNOTMIRROR_URL = "";
      services.tangled.appview = {
        enable = true;
        port = prt.tangled-appview;
        environmentFile = tpl."tangled-appview.env".path;

        appviewHost = dmn.git;
        jetstream.endpoint = "wss://jetstream2.us-east.bsky.network/subscribe";
        resend.sentFrom = "noreply@${dmn.git}";
        pds.host = "https://${sentinel.dmn.pds}";
        camo.host = "https://${sentinel.dmn.camo}";
        avatar.host = "https://${sentinel.dmn.avatar-server}";
      };

      services.tangled.spindle = {
        enable = true;

        server = {
          listenAddr = "0.0.0.0:${toString prt.tangled-spindle}";
          hostname = dmn.tangled-spindle;
          jetstreamEndpoint = "wss://jetstream2.us-east.bsky.network/subscribe";
          owner = "did:plc:majihettvb7ieflgmkvujecu";
          maxJobCount = 4;
        };

        pipelines.nixery = "nixery.dev";
        pipelines.workflowTimeout = "10m";
      };

      # thelessone.caddy.vHost.${dmn.git}.proxy.port = prt.tangled-appview;
      # thelessone.caddy.vHost.${dmn.tangled-spindle}.proxy.port = prt.tangled-spindle;
    };
}
