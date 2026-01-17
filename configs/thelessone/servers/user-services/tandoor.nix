{ config, ... }:

let
  cfg = config.services.tandoor-recipes;
in

{
  sops.secrets = {
    tandoor.owner = cfg.user;
    tandoor_email.owner = cfg.user;
  };

  services.tandoor-recipes = {
    enable = true;
    port = 45530;
    database.createLocally = true;

    extraConfig = {
      SECRET_KEY_FILE = config.sops.secrets.tandoor.path;

      MEDIA_ROOT = "/var/lib/tandoor-recipes";
      DB_ENGINE = "django.db.backends.postgresql";
      POSTGRES_HOST = "/run/postgresql";
      POSTGRES_USER = "tandoor_recipes";
      POSTGRES_DB = "tandoor_recipes";

      ENABLE_SIGNUP = 1;
      SPACE_AI_ENABLED = 0;
      ENABLE_PDF_EXPORT = 1;

      ACCOUNT_EMAIL_SUBJECT_PREFIX = "[Recipes] ";
      EMAIL_HOST = "mail.theless.one";
      EMAIL_PORT = 465;
      DEFAULT_FROM_EMAIL = "recipes@theless.one";
      EMAIL_HOST_USER = "recipes@theless.one";
      EMAIL_HOST_PASSWORD_FILE = config.sops.secrets.tandoor_email.path;
      EMAIL_USE_TLS = 0;
      EMAIL_USE_SSL = 1;
    };
  };

  systemd.tmpfiles.settings.tandoor-recipes."/var/lib/tandoor-recipes".Z = {
    inherit (cfg) user group;
    mode = "750";
  };
  users.users.caddy.extraGroups = [ cfg.group ];
  config'.caddy.vHost."recipes.theless.one" = {
    proxy.port = config.services.tandoor-recipes.port;
    useVpn = true;
    extraConfig = ''
      handle_path /media/* {
      	root * /var/lib/tandoor-recipes
      	file_server
      }
    '';
  };

  services.borgbackup.jobs.tandoor-recipes = {
    repo = "thelessone-borg@10.0.0.6:tandoor-recipes";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
    doInit = true;

    paths = "/var/lib/tandoor-recipes";

    encryption.mode = "none";
    compression = "zstd";

    startAt = "daily";
    persistentTimer = true;
    prune.keep = {
      within = "1d";
      daily = 14;
      weekly = 12;
      monthly = -1;
    };
  };
}
