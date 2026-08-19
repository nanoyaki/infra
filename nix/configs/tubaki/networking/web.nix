{
  flake.nixosModules.tubaki-web =
    {
      lib,
      config,
      pkgs,
      ...
    }:

    let
      inherit (config) prt;
      inherit (lib) mkOption;

      format = pkgs.formats.xml { };
      cfg = config.services.mailserver.autodiscovery;
    in

    {
      options.services.mailserver.autodiscovery.thunderbird.config = mkOption {
        inherit (format) type;
      };

      config = {
        services.mailserver.autodiscovery.thunderbird.config.clientConfig = {
          "@version" = "1.1";

          emailProvider = {
            "@id" = "nanoyaki.space";

            domain = [
              "nanoyaki.space"
              "theless.one"
              "aslija.com"
              "hanakretzer.de"
            ];

            displayName = "Nanoyaki.Space Mail";
            displayShortName = "Nanoyaki.Space";

            incomingServer = {
              "@type" = "imap";

              hostname = "mail.%EMAILDOMAIN%";
              port = 993;
              socketType = "SSL";
              username = "%EMAILADDRESS%";
              authentication = "password-cleartext";
            };

            outgoingServer = {
              "@type" = "smtp";

              hostname = "mail.%EMAILDOMAIN%";
              port = 465;
              socketType = "SSL";
              username = "%EMAILADDRESS%";
              authentication = "password-cleartext";
            };

            addressBook = {
              "@type" = "carddav";

              username = "%EMAILADDRESS%";
              authentication = "http-basic";
              serverURL = "https://dav.theless.one";
            };

            calendar = {
              "@type" = "caldav";

              username = "%EMAILADDRESS%";
              authentication = "http-basic";
              serverURL = "https://dav.theless.one";
            };
          };
        };

        users.users.caddy.extraGroups = [ "roundcube" ];
        services.caddy = {
          enable = true;
          enableReload = true;

          httpPort = prt.http;
          httpsPort = prt.https;
          openFirewall = true;

          globalConfig = ''
            auto_https disable_certs
          '';

          logFormat = ''
            output file /var/log/caddy/caddy.log {
              roll_size 100mb
              roll_keep 10
            }
            output stderr
            format console
            level INFO
          '';

          extraConfig = ''
            (errors) {
              handle_errors {
                respond "{err.status_code} - {err.status_text} > {err.id}" {err.status_code}
              }
            }

            (roundcube) {
              tls /var/lib/acme/{args[0]}/cert.pem /var/lib/acme/{args[0]}/key.pem

              @thunderbird {
                method GET
                path /mail/config-v1.1.xml
              }

              handle @thunderbird {
                try_files ${(format.generate "config-v1.1.xml" cfg.thunderbird.config).outPath}
              }

              handle {
                root * ${config.services.roundcube.package}/public_html

                encode zstd gzip
                file_server

                php_fastcgi unix/${config.services.phpfpm.pools.roundcube.socket} {
                  root ${config.services.roundcube.package}/public_html
                  resolve_root_symlink
                  capture_stderr
                }
              }
              
              import errors
            }
          '';

          virtualHosts."mail.nanoyaki.space".extraConfig = ''
            import roundcube nanoyaki.space
          '';

          virtualHosts."mail.aslija.com".extraConfig = ''
            import roundcube aslija.com
          '';

          virtualHosts."mail.theless.one".extraConfig = ''
            import roundcube theless.one
          '';
        };

        services.phpfpm.pools.roundcube.settings."listen.owner" = "caddy";
        services.phpfpm.pools.roundcube.settings."listen.group" = "caddy";
        services.roundcube = {
          enable = true;
          configureNginx = false;
          hostName = "mail.nanoyaki.space";
          maxAttachmentSize = config.mailserver.messageSizeLimit / 1024 / 1024;

          plugins = [ "managesieve" ];
          dicts = with pkgs.aspellDicts; [
            en
            de
          ];

          extraConfig = ''
            $config['log_logins'] = true;

            $config['imap_host'] = "ssl://mail.nanoyaki.space";
            $config['smtp_host'] = "ssl://mail.nanoyaki.space";
            $config['smtp_user'] = "%u";
            $config['smtp_pass'] = "%p";

            $config['managesieve_host'] = "tls://mail.nanoyaki.space";
            $config['managesieve_port'] = 4190;
            $config['managesieve_usetls'] = true;
          '';
        };

        services.fail2ban.jails.roundcube.enabled = true;
        services.fail2ban.jails.roundcube.settings = {
          filter = "roundcube-auth";
          action = "nftables-allports";
        };
      };
    };
}
