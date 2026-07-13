{
  flake.nixosModules.thelessone-firefly-iii =
    { config, ... }:

    let
      inherit (config) dmn prt sec;

      cfg = config.services.firefly-iii;
    in

    {
      prt.firefly-iii = 8035;
      dmn.finances = "finances.theless.one";
      dmn.firefly-iii-importer = "firefly-import.theless.one";

      sec = {
        "firefly-iii/secret".owner = cfg.user;
        "firefly-iii/oidc-id".owner = config.services.caddy.user;
        "firefly-iii/oidc-secret".owner = config.services.caddy.user;

        "firefly-iii/enable-id".owner = config.services.firefly-iii-data-importer.user;
        "firefly-iii/enable-key".owner = config.services.firefly-iii-data-importer.user;
        "firefly-iii/api-key".owner = config.services.firefly-iii-data-importer.user;
      };

      users.users.${cfg.user}.extraGroups = [ "no-reply" ];
      services.firefly-iii = {
        enable = true;

        poolConfig = {
          "php_admin_value[date.timezone]" = "Europe/Vienna";
          # Logging
          "php_admin_value[error_reporting]" = "E_ALL";
          "php_admin_flag[log_errors]" = true;
          "php_admin_flag[display_errors]" = false;
          "catch_workers_output" = true;
          "decorate_workers_output" = false;
        };

        settings = {
          APP_ENV = "production";
          APP_KEY_FILE = sec."firefly-iii/secret".path;
          APP_URL = "https://finances.theless.one";
          SITE_OWNER = "contact@nanoyaki.space";
          TZ = "Europe/Vienna";
          LOG_CHANNEL = "syslog";

          MAIL_HOST = dmn.mail;
          MAIL_PORT = prt.smtp-tls;
          MAIL_FROM = "no-reply@${dmn.self}";
          MAIL_USERNAME = "no-reply@${dmn.self}";
          MAIL_PASSWORD_FILE = sec.no-reply-password.path;

          AUTHENTICATION_GUARD = "remote_user_guard";
          AUTHENTICATION_GUARD_HEADER = "REMOTE_USER";
          AUTHENTICATION_GUARD_EMAIL = "REMOTE_EMAIL";
        };
      };

      services.firefly-iii-data-importer = {
        enable = true;

        poolConfig = {
          "php_admin_value[date.timezone]" = "Europe/Vienna";
          # Logging
          "php_admin_value[error_reporting]" = "E_ALL";
          "php_admin_flag[log_errors]" = true;
          "php_admin_flag[display_errors]" = false;
          "catch_workers_output" = true;
          "decorate_workers_output" = false;
        };

        settings = {
          APP_ENV = "local";
          APP_URL = "https://${dmn.firefly-iii-importer}";
          LOG_CHANNEL = "syslog";
          LOG_LEVEL = "debug";
          TZ = "Europe/Vienna";

          FIREFLY_III_URL = "http://127.0.0.1:${toString prt.firefly-iii}";
          VANITY_URL = "https://${dmn.finances}";
          FIREFLY_III_ACCESS_TOKEN_FILE = sec."firefly-iii/api-key".path;

          ENABLE_BANKING_APP_ID_FILE = sec."firefly-iii/enable-id".path;
          ENABLE_BANKING_PRIVATE_KEY_FILE = sec."firefly-iii/enable-key".path;
        };
      };

      users.users.${config.services.caddy.user}.extraGroups = [
        cfg.group
        config.services.firefly-iii-data-importer.group
      ];

      services.caddy.extraConfig = ''
        (firefly-iii) {
          root * ${cfg.package}/public

          encode zstd gzip
          file_server

          php_fastcgi unix/${config.services.phpfpm.pools.firefly-iii.socket} {
            root ${cfg.package}/public
            header_up REMOTE_USER {{http.request.header.X-Token-User-Name}}
            header_up REMOTE_EMAIL {{http.request.header.X-Token-User-Email}}
            capture_stderr
            resolve_root_symlink
          }
        }
      '';

      thelessone.caddy.vHost."http://127.0.0.1:${toString prt.firefly-iii}".extraConfig = ''
        import firefly-iii
      '';

      thelessone.caddy.vHost.${dmn.finances} = {
        extraConfig = ''
          @auth path /oauth2/*
          route @auth {
            authenticate with firefly-iii-portal
          }

          route /* {
            authorize with firefly-iii-policy

            handle {
              import firefly-iii
            }
          }
        '';
        useTailnet = true;
      };

      thelessone.caddy.vHost.${dmn.firefly-iii-importer} = {
        extraConfig = ''
          root * ${config.services.firefly-iii-data-importer.package}/public

          encode zstd gzip
          file_server

          php_fastcgi unix/${config.services.phpfpm.pools.firefly-iii-data-importer.socket} {
            root ${config.services.firefly-iii-data-importer.package}/public
            capture_stderr
            resolve_root_symlink
          }
        '';
        useTailnet = true;
      };

      services.caddy.globalConfig = ''
        order authenticate before respond
        security {
          oauth identity provider firefly-iii {
            realm firefly-iii
            driver generic
            delay_start 3
            client_id {file.${sec."firefly-iii/oidc-id".path}}
            client_secret {file.${sec."firefly-iii/oidc-secret".path}}
            scopes openid email profile
            base_auth_url https://id.theless.one
            metadata_url https://id.theless.one/.well-known/openid-configuration
          }

          authentication portal firefly-iii-portal {
            enable identity provider firefly-iii

            crypto default token lifetime 3600
            cookie insecure off
            cookie domain ${dmn.finances}
            trust login redirect uri domain exact ${dmn.finances} path prefix /

            transform user {
              match realm firefly-iii
              action add role user
            }
          }

          authorization policy firefly-iii-policy {
            set auth url https://${dmn.finances}/oauth2/firefly-iii
            allow roles user
            inject headers with claims
          }
        }
      '';
    };
}
