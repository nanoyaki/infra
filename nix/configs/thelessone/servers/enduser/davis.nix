{
  flake.nixosModules.thelessone-davis =
    { lib, config, ... }:

    let
      cfg = config.services.davis;
      dirCfg.d = {
        inherit (cfg) user group;
        mode = "700";
      };
    in

    {
      sops.secrets = {
        davis-app-secret = { };
        davis-admin-password = { };
        no-reply-password = { };
      };

      sops.templates.mailer-dsn.content = ''
        smtp://no-reply:${config.sops.placeholder.no-reply-password}@theless.one
      '';

      services.davis = {
        enable = true;
        hostname = "dav.theless.one";
        appSecretFile = config.sops.secrets.davis-app-secret.path;

        adminLogin = "admin";
        adminPasswordFile = config.sops.secrets.davis-admin-password.path;

        mail.dsnFile = config.sops.templates.mailer-dsn.path;
        mail.inviteFromAddress = "no-reply@theless.one";

        config = {
          CALDAV_ENABLED = true;
          CARDDAV_ENABLED = true;
          WEBDAV_ENABLED = lib.mkForce true;
          PUBLIC_CALENDARS_ENABLED = true;

          AUTH_METHOD = "IMAP";
          IMAP_AUTH_URL = "imap.theless.one";
          IMAP_ENCRYPTION_METHOD = "tls";
          IMAP_CERTIFICATE_VALIDATION = true;
          IMAP_AUTH_USER_AUTOCREATE = true;

          WEBDAV_TMP_DIR = "/srv/webdav/tmp";
          WEBDAV_PUBLIC_DIR = "/srv/webdav/public";
          WEBDAV_HOMES_DIR = "/srv/webdav/homes";

          # misc
          BIRTHDAY_REMINDER_OFFSET = "PT9H";
          LOG_FILE_PATH = lib.mkForce "/var/log/davis/%kernel.environment%.log";
          SYMFONY_TRUSTED_PROXIES = "127.0.0.1";
          APP_ENV = "prod";
        };

        database.driver = "postgresql";
        database.createLocally = true;
      };

      systemd.services.caddy.serviceConfig.ReadWritePaths = [ config.services.phpfpm.pools.davis.socket ];
      users.users.${config.services.caddy.user}.extraGroups = [ cfg.group ];
      thelessone.caddy.vHost."dav.theless.one".extraConfig = ''
        root * ${cfg.package}/public
        encode zstd gzip

        @caldav path_regexp ^/\.well-known/(caldav|carddav)$
        redir @caldav /dav/ 302

        php_fastcgi unix/${config.services.phpfpm.pools.davis.socket}

        file_server

        @dotfiles {
          not path /.well-known/*
          path /.*
        }
        redir @dotfiles /

        import error_handling
      '';

      systemd.tmpfiles.settings."10-davis" = {
        "/srv/webdav" = dirCfg;
        "/srv/webdav/tmp" = dirCfg;
        "/srv/webdav/public" = dirCfg;
        "/srv/webdav/homes" = dirCfg;

        "/var/log/davis".d = {
          inherit (cfg) user group;
          mode = "750";
        };
      };
    };
}
