{
  lib,
  pkgs,
  config,
  ...
}:

{
  sops = {
    secrets = {
      "dynamicdns/vappie.space" = { };

      "porkbun/api-key" = { };
      "porkbun/secret-api-key" = { };
      "porkbun-nano/api-key" = { };
      "porkbun-nano/secret-api-key" = { };
    };

    templates."oink.json".content = builtins.toJSON {
      global = {
        secretapikey = config.sops.placeholder."porkbun/secret-api-key";
        apikey = config.sops.placeholder."porkbun/api-key";
        interval = 900;
        ttl = 600;
      };

      domains = [
        {
          secretapikey = config.sops.placeholder."porkbun-nano/secret-api-key";
          apikey = config.sops.placeholder."porkbun-nano/api-key";
          domain = "nanoyaki.space";
          subdomain = "";
        }
        {
          secretapikey = config.sops.placeholder."porkbun-nano/secret-api-key";
          apikey = config.sops.placeholder."porkbun-nano/api-key";
          domain = "nanoyaki.space";
          subdomain = "*";
        }
        {
          domain = "theless.one";
          subdomain = "at01";
        }
        # Remove this soon
        {
          domain = "theless.one";
          subdomain = "";
        }
        {
          domain = "theless.one";
          subdomain = "*";
        }
      ];
    };
  };

  config'.dynamicdns = {
    enable = true;

    domains."vappie.space" = {
      passwordFile = config.sops.secrets."dynamicdns/vappie.space".path;
      subdomains = [
        "*"
        "@"
      ];
    };
  };

  users.users.acme-remote = {
    isSystemUser = true;
    inherit (config.services.caddy) group;
    home = "/var/lib/acme-remote";
    homeMode = "750";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILop1PDNFg/4cifMlfwg5wyJcJDpankE01FIt4K104nW"
    ];
  };

  systemd.services.oink = {
    description = "Dynamic DNS client for Porkbun";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      LoadCredential = "oink.json:${config.sops.templates."oink.json".path}";
      ExecStart = "${lib.getExe pkgs.oink} -c \${CREDENTIALS_DIRECTORY}/oink.json -v";
      Restart = "always";
      Type = "simple";

      # Hardening
      DynamicUser = true;
      CapabilityBoundingSet = "";
      SystemCallFilter = [ "@system-service" ];

      NoNewPrivileges = true;
      ProtectClock = true;
      RestrictNamespaces = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];
      MemoryDenyWriteExecute = true;
      ProtectHostname = true;

      ProtectSystem = "strict";
      PrivateTmp = true;
      ProtectHome = true;
      PrivateDevices = true;
      ProtectControlGroups = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectProc = "invisible";
    };
  };

  sops.templates."theless.one.acme.env".file = (pkgs.formats.keyValue { }).generate "acme.env" {
    PORKBUN_API_KEY = config.sops.placeholder."porkbun/api-key";
    PORKBUN_SECRET_API_KEY = config.sops.placeholder."porkbun/secret-api-key";
  };

  sops.templates."nanoyaki.space.acme.env".file = (pkgs.formats.keyValue { }).generate "acme.env" {
    PORKBUN_API_KEY = config.sops.placeholder."porkbun-nano/api-key";
    PORKBUN_SECRET_API_KEY = config.sops.placeholder."porkbun-nano/secret-api-key";
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      inherit (config.services.caddy) group;
      email = "contact@nanoyaki.space";

      dnsProvider = "porkbun";
      dnsResolver = "173.245.58.37:53";
      dnsPropagationCheck = true;
    };

    certs."mail.theless.one" = {
      environmentFile = config.sops.templates."theless.one.acme.env".path;
      extraDomainNames = [ "at01.theless.one" ];
    };

    certs."nanoyaki.space" = {
      environmentFile = config.sops.templates."nanoyaki.space.acme.env".path;
      extraDomainNames = [ "*.nanoyaki.space" ];
    };
  };
}
