{
  flake.nixosModules.thelessone-tandoor =
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
        sec
        tpl
        plh
        ;

      cfg = config.services.tandoor-recipes;
    in

    {
      prt.tandoor-recipes = 8010;
      dmn.tandoor-recipes = "recipes.theless.one";

      sec = {
        "tandoor/secret".owner = cfg.user;
        "tandoor/oidc-id" = { };
        "tandoor/oidc-secret" = { };
      };

      tpl."tandoor.env".file = pkgs.writeEnv "tandoor.env.template" {
        SOCIALACCOUNT_PROVIDERS = builtins.toJSON {
          openid_connect.APPS = [
            {
              provider_id = "pocket-id";
              name = "Pocket ID";
              client_id = plh."tandoor/oidc-id";
              secret = plh."tandoor/oidc-secret";
              settings.server_url = "https://${dmn.pocket-id}/.well-known/openid-configuration";
            }
          ];
        };
      };

      systemd.services.tandoor-recipes.wantedBy = lib.mkForce [ "server-services.target" ];
      systemd.services.tandoor-recipes.serviceConfig.EnvironmentFile = tpl."tandoor.env".path;
      services.tandoor-recipes = {
        enable = true;
        port = prt.tandoor-recipes;
        database.createLocally = true;

        extraConfig = {
          ALLOWED_HOSTS = dmn.tandoor-recipes;
          SECRET_KEY_FILE = sec."tandoor/secret".path;

          MEDIA_ROOT = "/var/lib/tandoor-recipes/media";
          DB_ENGINE = "django.db.backends.postgresql";
          POSTGRES_HOST = "/run/postgresql";
          POSTGRES_USER = "tandoor_recipes";
          POSTGRES_DB = "tandoor_recipes";

          ENABLE_LLMS = 0;
          ENABLE_SIGNUP = 1;
          SPACE_AI_ENABLED = 0;
          ENABLE_PDF_EXPORT = 1;

          ACCOUNT_EMAIL_SUBJECT_PREFIX = "[Recipes] ";
          EMAIL_HOST = dmn.mail;
          EMAIL_PORT = prt.smtp-tls;
          DEFAULT_FROM_EMAIL = "no-reply@${dmn.self}";
          EMAIL_HOST_USER = "no-reply@${dmn.self}";
          EMAIL_HOST_PASSWORD_FILE = sec.no-reply-password.path;
          EMAIL_USE_TLS = 0;
          EMAIL_USE_SSL = 1;

          # OIDC
          SOCIAL_PROVIDERS = "allauth.socialaccount.providers.openid_connect";
        };
      };

      systemd.tmpfiles.settings.tandoor-recipes."/var/lib/tandoor-recipes".Z = {
        inherit (cfg) user group;
        mode = "750";
      };

      thelessone.caddy.vHost.${dmn.tandoor-recipes} = {
        proxy.port = prt.tandoor-recipes;
        useTailnet = true;
      };

      thelessone.backups.tandoor-recipes.paths = [ "/var/lib/tandoor-recipes" ];
    };
}
