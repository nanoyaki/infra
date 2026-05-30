{ inputs, ... }:

{
  flake.nixosModules.thelessone-mailserver =
    { lib, config, ... }:

    {
      imports = [ inputs.snm.nixosModules.mailserver ];

      sops.secrets = {
        "mailserver/postmaster" = { };
        "mailserver/nanoyaki" = { };
        "mailserver/thelessone" = { };
        "mailserver/no-reply" = { };
        "mailserver/meilyne" = { };
        "mailserver/aslija-personal" = { };
        "mailserver/aslija-business" = { };
      };

      networking.firewall.allowedTCPPorts = [
        465
        993
      ];

      systemd.services = {
        rspamd.wantedBy = lib.mkForce [ "server-services.target" ];
        postfix.wantedBy = lib.mkForce [ "server-services.target" ];
        dovecot.wantedBy = lib.mkForce [ "server-services.target" ];
      };

      mailserver = {
        enable = true;
        virusScanning = true;
        stateVersion = 3;
        fqdn = "mail.theless.one";
        domains = [
          "theless.one"
          "nanoyaki.space"
          "aslija.com"
        ];

        accounts = {
          "postmaster@theless.one" = {
            hashedPasswordFile = config.sops.secrets."mailserver/postmaster".path;
            aliases = [ "postmaster@nanoyaki.space" ];
          };

          "nanoyaki@theless.one" = {
            hashedPasswordFile = config.sops.secrets."mailserver/nanoyaki".path;
            aliases = [
              "hana@theless.one"
              "hanakretzer@nanoyaki.space"
              "hana@nanoyaki.space"
              "nanoyaki@nanoyaki.space"
              "nano@nanoyaki.space"
              "contact@nanoyaki.space"

              "scpsl@theless.one"
            ];
            aliasesRegexp = [ ''/^.*(\.|\+).*@nanoyaki\.space$/'' ];
            catchAll = [ "nanoyaki.space" ];
          };

          "thelessone@theless.one" = {
            hashedPasswordFile = config.sops.secrets."mailserver/thelessone".path;
            aliases = [
              "thomas@theless.one"
              "contact@theless.one"
            ];
          };

          "meilyne@nanoyaki.space" = {
            hashedPasswordFile = config.sops.secrets."mailserver/meilyne".path;
            aliasesRegexp = [ ''/^meilyne(\.|\+).*@nanoyaki\.space$/'' ];
          };

          "personal@aslija.com" = {
            hashedPasswordFile = config.sops.secrets."mailserver/aslija-personal".path;
            aliasesRegexp = [ ''/^personal\+.*@aslija\.com$/'' ];
          };

          "business@aslija.com" = {
            hashedPasswordFile = config.sops.secrets."mailserver/aslija-business".path;
            aliases = [ "inquiry@aslija.com" ];
          };

          "no-reply@theless.one" = {
            hashedPasswordFile = config.sops.secrets."mailserver/no-reply".path;
            sendOnly = true;
          };
        };

        x509.useACMEHost = "theless.one";

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
