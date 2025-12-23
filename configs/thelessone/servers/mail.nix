{ inputs, config, ... }:

{
  imports = [ inputs.snm.nixosModules.mailserver ];

  sops.secrets = {
    "mailserver/postmaster" = { };
    "mailserver/nanoyaki" = { };
    "mailserver/thelessone" = { };
    "mailserver/vaultwarden" = { };
    "mailserver/calendar" = { };
    "mailserver/git" = { };
    "mailserver/recipes" = { };
  };

  mailserver = {
    enable = true;
    stateVersion = 3;
    fqdn = "mail.theless.one";
    domains = [
      "theless.one"
      "nanoyaki.space"
    ];

    loginAccounts = {
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

      "vaultwarden@theless.one" = {
        sendOnly = true;
        hashedPasswordFile = config.sops.secrets."mailserver/vaultwarden".path;
      };

      "calendar@theless.one" = {
        sendOnly = true;
        hashedPasswordFile = config.sops.secrets."mailserver/calendar".path;
      };

      "git@theless.one" = {
        sendOnly = true;
        hashedPasswordFile = config.sops.secrets."mailserver/git".path;
      };

      "recipes@theless.one" = {
        sendOnly = true;
        hashedPasswordFile = config.sops.secrets."mailserver/recipes".path;
      };
    };

    x509.useACMEHost = "theless.one";

    dkimSigning = true;
    dkimKeyType = "rsa";
    dkimKeyBits = 4096;
    dkimSelector = "mail";

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
  '';

  services.borgbackup.jobs.mail = {
    repo = "thelessone-borg@10.0.0.6:mail";
    environment.BORG_RSH = "ssh -i ${config.sops.secrets.id_borg_thelessone.path}";
    doInit = true;

    paths = "/var";
    patterns = [
      "+ /var/vmail"
      "+ /var/sieve"
      "+ /var/lib/redis-rspamd"
      "+ /var/dkim"
      "- **"
    ];

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
