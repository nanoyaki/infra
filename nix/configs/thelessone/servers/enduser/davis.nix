{ withSystem, ... }:

{
  flake.nixosModules.thelessone-davis =
    { lib, config, ... }:

    let
      cfg = config.services.davis;

      inherit (config)
        prt
        dmn
        sec
        plh
        tpl
        ;

      dirCfg.d = {
        inherit (cfg) user group;
        mode = "700";
      };
    in

    {
      sec = {
        davis-app-secret = { };
        davis-admin-password = { };
      };

      tpl.mailer-dsn.content = ''
        smtp://no-reply:${plh.no-reply-password}@theless.one
      '';

      dmn.davis = "dav.theless.one";

      systemd.services.davis-env-setup.wantedBy = lib.mkForce [ "server-services.target" ];
      systemd.services.davis-db-migrate.wantedBy = lib.mkForce [ "server-services.target" ];
      services.davis = {
        enable = true;
        nginx = null;
        hostname = dmn.davis;
        appSecretFile = sec.davis-app-secret.path;

        adminLogin = "admin";
        adminPasswordFile = sec.davis-admin-password.path;

        mail.dsnFile = tpl.mailer-dsn.path;
        mail.inviteFromAddress = "no-reply@theless.one";

        config = {
          CALDAV_ENABLED = true;
          CARDDAV_ENABLED = true;
          WEBDAV_ENABLED = lib.mkForce true;
          PUBLIC_CALENDARS_ENABLED = true;

          AUTH_METHOD = "IMAP";
          IMAP_AUTH_URL = "${dmn.mail}:${toString prt.imap-tls}";
          IMAP_ENCRYPTION_METHOD = "tls";
          IMAP_CERTIFICATE_VALIDATION = true;
          IMAP_AUTH_USER_AUTOCREATE = true;

          WEBDAV_TMP_DIR = "/srv/webdav/tmp";
          WEBDAV_PUBLIC_DIR = "/srv/webdav/public";
          WEBDAV_HOMES_DIR = "/srv/webdav-homes";

          # misc
          BIRTHDAY_REMINDER_OFFSET = "PT9H";
          LOG_FILE_PATH = lib.mkForce "/var/log/davis/%kernel.environment%.log";
          SYMFONY_TRUSTED_PROXIES = "127.0.0.1,${dmn.davis}";
          APP_ENV = "prod";
        };

        database.driver = "postgresql";
        database.createLocally = true;
      };

      services.phpfpm.pools.davis.settings."listen.group" = "caddy";
      thelessone.caddy.vHost.${dmn.davis} = {
        serverAliases = [ dmn.mail ];
        extraConfig = ''
          root * ${cfg.package}/public
          encode zstd gzip
          header {
            -Server
            -X-Powered-By
            Strict-Transport-Security max-age=31536000;
            X-Content-Type-Options nosniff
            Referrer-Policy no-referrer-when-downgrade
          }

          @caldav path_regexp ^/\.well-known/(caldav|carddav)$
          redir @caldav /dav/ 301

          php_fastcgi unix/${config.services.phpfpm.pools.davis.socket} {
            root ${cfg.package}/public
            resolve_root_symlink
          }

          file_server

          @dotfiles {
            not path /.well-known/*
            path /.*
          }
          redir @dotfiles /
        '';
      };

      systemd.tmpfiles.settings."10-davis" = {
        "/srv/webdav" = dirCfg;
        "/srv/webdav/tmp" = dirCfg;
        "/srv/webdav/public" = dirCfg;
        "/srv/webdav-homes" = dirCfg;

        "/var/log/davis".d = {
          inherit (cfg) user group;
          mode = "750";
        };
      };

      thelessone.backups.dav.paths = [ cfg.dataDir ];
    };

  perSystem =
    { pkgs, ... }:

    {
      packages.davis = pkgs.davis.overrideAttrs (
        finalAttrs: prevAttrs:

        {
          php = pkgs.php.withExtensions (
            { all, enabled }:

            enabled
            ++ [
              all.imap
              all.pdo_pgsql
            ]
          );

          passthru = prevAttrs.passthru // {
            inherit (finalAttrs) php;
          };
        }
      );
    };

  flake.overlays.davis =
    _: prev:

    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:

      {
        inherit (config.packages) davis;
      }
    );
}
