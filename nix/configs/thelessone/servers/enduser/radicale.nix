{
  flake.nixosModules.thelessone-radicale =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      inherit (lib)
        generators
        concatMapStringsSep
        concatStringsSep
        mkForce
        getExe'
        ;

      format = pkgs.formats.ini {
        listToValue = concatMapStringsSep ", " (generators.mkValueStringDefault { });
      };

      cfg = config.services.radicale;
    in

    {
      sops.secrets.radicale-smtp-password.owner = "radicale";
      sops.secrets."mailserver/calendar" = { };

      services.radicale = {
        enable = true;
        settings = {
          server.hosts = [ "0.0.0.0:5232" ];

          auth = {
            type = "imap";
            imap_host = "imap.theless.one";
            imap_security = "tls";

            urldecode_username = true;
          };

          storage = {
            filesystem_folder = "/var/lib/radicale/collections";

            predefined_collections = lib.replaceStrings [ "\n" ] [ " " ] (
              builtins.toJSON {
                def-addressbook = {
                  "D:displayname" = "Personal Address Book";
                  tag = "VADDRESSBOOK";
                };

                def-calendar = {
                  "C:supported-calendar-component-set" = "VEVENT,VJOURNAL,VTODO";
                  "D:displayname" = "Personal Calendar";
                  tag = "VCALENDAR";
                };
              }
            );
          };

          web.type = "none";

          hook = {
            type = "email";

            smtp_server = "https://mail.theless.one";
            smtp_port = 465;
            smtp_security = "tls";
            smtp_ssl_verify_mode = "REQUIRED";
            smtp_username = "calendar@theless.one";
            from_email = "calendar@theless.one";
          };
        };

        rights = {
          ownercol = {
            user = ".+";
            collection = "{user}(/)?";
            permissions = "RW";
          };

          owner = {
            user = ".+";
            collection = "{user}/[^/]+";
            permissions = "rw";
          };

          public = {
            user = ".+";
            collection = "";
            permissions = "R";
          };
        };

        extraArgs = [
          ''--hook-smtp-password="$(cat ${config.sops.secrets.radicale-smtp-password.path})"''
        ];
      };

      systemd.services.radicale.serviceConfig.ExecStart = mkForce (
        concatStringsSep " " (
          [
            (getExe' pkgs.radicale "radicale")
            "-C"
            (format.generate "radicale.conf" cfg.settings)
          ]
          ++ cfg.extraArgs
        )
      );

      mailserver.accounts."calendar@theless.one" = {
        sendOnly = true;
        hashedPasswordFile = config.sops.secrets."mailserver/calendar".path;
      };

      thelessone.caddy.vHost."calendar.theless.one".proxy.port = 5232;

      services.borgbackup.jobs.dav = {
        repo = "thelessone-borg@10.0.0.6:dav";
        environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
        doInit = true;

        paths = "/var/lib/radicale";

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
    };
}
