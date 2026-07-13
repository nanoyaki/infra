{ inputs, ... }:

{
  flake.nixosModules.tubaki-mail =
    { config, ... }:

    let
      inherit (config) prt sec;

      mkDKIMSecret = domain: {
        mode = "400";
        owner = "rspamd";
        group = "rspamd";
        path = "${config.mailserver.dkim.keyDirectory}/${domain}.${config.mailserver.dkim.defaults.selector}.key";
      };
    in

    {
      imports = [ inputs.snm.nixosModules.mailserver ];

      sec = {
        "dkim/nanoyaki.space" = mkDKIMSecret "nanoyaki.space";
        "dkim/aslija.com" = mkDKIMSecret "aslija.com";
        "dkim/theless.one" = mkDKIMSecret "theless.one";
        "dkim/hanakretzer.de" = mkDKIMSecret "hanakretzer.de";

        "mail/postmaster@nanoyaki.space" = { };
        "mail/no-reply@theless.one" = { };
        "mail/contact@hanakretzer.de" = { };
        "mail/meilyne@nanoyaki.space" = { };
        "mail/business@aslija.com" = { };
        "mail/personal@aslija.com" = { };
        "mail/thelessone@theless.one" = { };
      };

      networking.firewall.allowedTCPPorts = [
        prt.smtp-tls
        prt.imap-tls
        prt.manage-sieve
      ];

      mailserver = {
        enable = true;
        stateVersion = 5;

        systemName = "Nanoyaki.Space Mail";
        systemContact = "postmaster@nanoyaki.space";

        x509.useACMEHost = config.networking.domain;
        inherit (config.networking) fqdn;
        domains = [
          config.networking.domain
          "theless.one"
          "aslija.com"
          "hanakretzer.de"
        ];

        dkim.enable = true;
        dkim.defaults = {
          selector = "mail";
          # FIXME: I've had problems with ed25519 for some reason...
          # will revisit and fix in the future!
          keyType = "rsa";
          keyLength = 4096;
        };

        dmarcReporting.enable = true;
        tlsrpt.enable = true;

        # SSL Imap only!
        enableImap = false;
        enableImapSsl = true;

        # Disable POP3
        enablePop3 = false;
        enablePop3Ssl = false;
      };

      mailserver.mailboxes = {
        Drafts = {
          auto = "subscribe";
          special_use = "\\Drafts";
        };
        Sent = {
          auto = "subscribe";
          special_use = "\\Sent";
        };

        Trash = {
          auto = "subscribe";
          special_use = "\\Trash";
          fts_autoindex = false;
        };
        Junk = {
          auto = "subscribe";
          special_use = "\\Junk";
          fts_autoindex = false;
        };

        Archive = {
          auto = "subscribe";
          special_use = "\\Archive";
        };
        Important = {
          auto = "subscribe";
          special_use = "\\Flagged";
        };
      };

      mailserver.accounts = {
        "postmaster@nanoyaki.space" = {
          aliases = [
            "abuse@nanoyaki.space"
            "postmaster@hanakretzer.de"
            "abuse@aslija.com"
            "postmaster@aslija.com"
            "abuse@theless.one"
            "postmaster@theless.one"
          ];
          hashedPasswordFile = sec."mail/postmaster@nanoyaki.space".path;
        };

        "no-reply@theless.one" = {
          hashedPasswordFile = sec."mail/no-reply@theless.one".path;
          sendOnly = true;
        };

        "contact@hanakretzer.de" = {
          aliases = [ "contact@nanoyaki.space" ];
          catchAll = [
            "nanoyaki.space"
            "hanakretzer.de"
          ];

          hashedPasswordFile = sec."mail/contact@hanakretzer.de".path;
        };

        "meilyne@nanoyaki.space" = {
          hashedPasswordFile = sec."mail/meilyne@nanoyaki.space".path;
          aliasesRegexp = [ ''/^meilyne(\.|\+).*@nanoyaki\.space$/'' ];
        };

        "business@aslija.com" = {
          aliases = [ "inquiry@aslija.com" ];
          hashedPasswordFile = sec."mail/business@aslija.com".path;
        };

        "personal@aslija.com" = {
          aliasesRegexp = [ ''/^personal\+.*@aslija\.com$/'' ];
          hashedPasswordFile = sec."mail/personal@aslija.com".path;
        };

        "thelessone@theless.one" = {
          hashedPasswordFile = sec."mail/thelessone@theless.one".path;
          aliases = [
            "thomas@theless.one"
            "contact@theless.one"
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
    };
}
