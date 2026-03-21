{ inputs, ... }:

{
  flake.nixosModules.thelessone-tangledAppview =
    { config, pkgs, ... }:

    let
      plh = config.sops.placeholder;
    in

    {
      imports = [ inputs.tangled.nixosModules.appview ];

      sops.secrets = {
        "tangled/camo" = { };
        "tangled/client-secret" = { };
        "tangled/client-kid" = { };
        "tangled/cookie-secret" = { };
        "tangled/app-password" = { };
        "tangled/alt-app-password" = { };
        "tangled/pds-admin-password" = { };
      };

      sops.templates."tangled-appview.env".file = pkgs.writeEnv "tangled-appview.env.template" {
        TANGLED_CAMO_SHARED_SECRET = plh."tangled/camo";
        TANGLED_OAUTH_CLIENT_SECRET = plh."tangled/client-secret";
        TANGLED_OAUTH_CLIENT_KID = plh."tangled/client-kid";
        TANGLED_COOKIE_SECRET = plh."tangled/cookie-secret";
        TANGLED_APP_PASSWORD = plh."tangled/app-password";
        TANGLED_ALT_APP_PASSWORD = plh."tangled/alt-app-password";
        TANGLED_PDS_ADMIN_SECRET = "'${plh."tangled/pds-admin-password"}'";
      };

      services.tangled.appview = {
        enable = false;
        port = 33190;
        environmentFile = config.sops.templates."tangled-appview.env".path;

        appviewHost = "git.theless.one";
        jetstream.endpoint = "wss://jetstream2.us-east.bsky.network/subscribe";
        resend.sentFrom = "noreply@git.theless.one";
        pds.host = "https://pds.nanoyaki.space";
        camo.host = "https://camo.nanoyaki.space";
        avatar.host = "https://avatars.nanoyaki.space";
      };

      # thelessone.caddy.vHost."git.theless.one".proxy.port = config.services.tangled.appview.port;
    };
}
