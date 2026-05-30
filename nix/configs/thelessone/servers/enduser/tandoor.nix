{
  flake.nixosModules.thelessone-tandoor =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      cfg = config.services.tandoor-recipes;

      plh = config.sops.placeholder;
    in

    {
      sops.secrets = {
        "tandoor/secret".owner = cfg.user;
        "tandoor/oidc-id" = { };
        "tandoor/oidc-secret" = { };
      };

      sops.templates."tandoor.env".file = pkgs.writeEnv "tandoor.env.template" {
        SOCIALACCOUNT_PROVIDERS = builtins.toJSON {
          openid_connect.APPS = [
            {
              provider_id = "pocket-id";
              name = "Pocket ID";
              client_id = plh."tandoor/oidc-id";
              secret = plh."tandoor/oidc-secret";
              settings.server_url = "https://id.theless.one/.well-known/openid-configuration";
            }
          ];
        };
      };

      systemd.services.tandoor-recipes.wantedBy = lib.mkForce [ "server-services.target" ];
      systemd.services.tandoor-recipes.serviceConfig.EnvironmentFile =
        config.sops.templates."tandoor.env".path;
      services.tandoor-recipes = {
        enable = true;
        port = 45530;
        database.createLocally = true;

        extraConfig = {
          ALLOWED_HOSTS = "recipes.theless.one";
          SECRET_KEY_FILE = config.sops.secrets."tandoor/secret".path;

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
          EMAIL_HOST = "mail.theless.one";
          EMAIL_PORT = 465;
          DEFAULT_FROM_EMAIL = "no-reply@theless.one";
          EMAIL_HOST_USER = "no-reply@theless.one";
          EMAIL_HOST_PASSWORD_FILE = config.sops.secrets.no-reply-password.path;
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

      thelessone.caddy.vHost."recipes.theless.one" = {
        proxy = {
          inherit (config.services.tandoor-recipes) port;
        };
        useTailnet = true;
      };

      thelessone.backups.tandoor-recipes.paths = [ "/var/lib/tandoor-recipes" ];
    };
}
