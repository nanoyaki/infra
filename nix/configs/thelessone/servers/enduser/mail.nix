{ inputs, ... }:

{
  flake.nixosModules.thelessone-mailserver =
    { lib, config, ... }:

    let
      inherit (config) prt dmn sec;
    in

    {
      imports = [ inputs.snm.nixosModules.mailserver ];

      sec = {
        "mailserver/postmaster" = { };
        "mailserver/nanoyaki" = { };
        "mailserver/thelessone" = { };
        "mailserver/no-reply" = { };
        "mailserver/meilyne" = { };
        "mailserver/aslija-personal" = { };
        "mailserver/aslija-business" = { };

        no-reply-password = {
          mode = "0440";
          group = "no-reply";
        };
      };

      users.groups.no-reply = { };

      networking.firewall.allowedTCPPorts = [
        prt.smtp-tls
        prt.imap-tls
      ];

      systemd.services = {
        rspamd.wantedBy = lib.mkForce [ "server-services.target" ];
        postfix.wantedBy = lib.mkForce [ "server-services.target" ];
        dovecot.wantedBy = lib.mkForce [ "server-services.target" ];
      };

      dmn = {
        mail = "mail.theless.one";
        nanoyaki-space = "nanoyaki.space";
        aslija-com = "aslija.com";
      };

      mailserver = {
        enable = true;
        virusScanning = true;
        stateVersion = 3;
        fqdn = dmn.mail;
        domains = [
          dmn.self
          dmn.nanoyaki-space
          dmn.aslija-com
        ];

        accounts = {
          "postmaster@${dmn.self}" = {
            hashedPasswordFile = sec."mailserver/postmaster".path;
            aliases = [ "postmaster@${dmn.nanoyaki-space}" ];
          };

          "nanoyaki@${dmn.self}" = {
            hashedPasswordFile = sec."mailserver/nanoyaki".path;
            aliases = [
              "hana@${dmn.self}"
              "hanakretzer@${dmn.nanoyaki-space}"
              "hana@${dmn.nanoyaki-space}"
              "nanoyaki@${dmn.nanoyaki-space}"
              "nano@${dmn.nanoyaki-space}"
              "contact@${dmn.nanoyaki-space}"

              "scpsl@${dmn.self}"
            ];
            aliasesRegexp = [ ''/^.*(\.|\+).*@nanoyaki\.space$/'' ];
            catchAll = [ "nanoyaki.space" ];
          };

          "thelessone@${dmn.self}" = {
            hashedPasswordFile = sec."mailserver/thelessone".path;
            aliases = [
              "thomas@${dmn.self}"
              "contact@${dmn.self}"
            ];
          };

          "meilyne@${dmn.nanoyaki-space}" = {
            hashedPasswordFile = sec."mailserver/meilyne".path;
            aliasesRegexp = [ ''/^meilyne(\.|\+).*@nanoyaki\.space$/'' ];
          };

          "personal@${dmn.aslija-com}" = {
            hashedPasswordFile = sec."mailserver/aslija-personal".path;
            aliasesRegexp = [ ''/^personal\+.*@aslija\.com$/'' ];
          };

          "business@${dmn.aslija-com}" = {
            hashedPasswordFile = sec."mailserver/aslija-business".path;
            aliases = [ "inquiry@${dmn.aslija-com}" ];
          };

          "no-reply@${dmn.self}" = {
            hashedPasswordFile = sec."mailserver/no-reply".path;
            sendOnly = true;
          };
        };

        x509.useACMEHost = dmn.self;

        dkim.enable = true;
        dkim.defaults = {
          keyType = "rsa";
          keyLength = 4096;
          selector = "mail";
        };

        dmarcReporting.enable = true;

        fullTextSearch = {
          substringSearch = true;
          languages = [
            "en"
            "de"
          ];
          filters = [
            "normalizer-icu"
            "snowball"
          ];
        };
      };

      services.rspamd.locals."multimap.conf".text = ''
        NIXOS_CONFIG_WHITELIST {
          type = "from";
          filter = "email:domain";
          map = "/etc/rspamd/local.d/domain_whitelist.map";
          action = "accept";
          description = "Whitelisted domains in the nixos configuration";
        }
      '';

      services.rspamd.locals."domain_whitelist.map".text = ''
        gryphline.com
        tangled.org
        notifs.tangled.org
      '';

      thelessone.backups.mail.paths = [
        "/var/vmail"
        "/var/sieve"
        "/var/lib/redis-rspamd"
        "/var/dkim"
      ];
    };
}
